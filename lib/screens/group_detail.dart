import 'package:frontend_proyecto/utils/theme.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import 'package:frontend_proyecto/services/feed_service.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:frontend_proyecto/utils/platform_reload.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _svc    = FeedService();
  final _scroll = ScrollController();

  List<FeedPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  Timer? _pollTimer;

  int get _groupId => widget.group['idCommunity'] as int;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
    _listenToRealtimeUpdates();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _fcmSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    try {
      final latest = await _svc.getFeed(page: 1, groupId: _groupId);
      if (!mounted || latest.isEmpty) return;
      final existingIds = _posts.map((p) => p.id).toSet();
      final newPosts = latest.where((p) => !existingIds.contains(p.id)).toList();
      if (newPosts.isNotEmpty) {
        setState(() => _posts.insertAll(0, newPosts));
      }
    } catch (_) {}
  }

  void _listenToRealtimeUpdates() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notifType = message.data['notif_type'];
      if (notifType == 'post_edited') {
        final postId = int.tryParse(message.data['post_id'] ?? '');
        final content = message.data['content'];
        if (postId != null && content != null) {
          final index = _posts.indexWhere((p) => p.id == postId);
          if (index != -1 && mounted) {
            setState(() {
              _posts[index].content = content;
            });
          }
        }
      } else if (notifType == 'post_deleted') {
        final postId = int.tryParse(message.data['post_id'] ?? '');
        if (postId != null) {
          if (mounted) {
            setState(() {
              _posts.removeWhere((p) => p.id == postId);
            });
          }
        }
      }
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _page = 1; _hasMore = true; });
    try {
      final posts = await _svc.getFeed(page: 1, groupId: _groupId);
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
          if (posts.length < 10) _hasMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _svc.getFeed(page: _page + 1, groupId: _groupId);
      if (mounted) {
        if (more.isEmpty) {
          setState(() => _hasMore = false);
        } else {
          setState(() {
            _posts.addAll(more);
            _page++;
            if (more.length < 10) _hasMore = false;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMore = false);
  }

  void _openNewPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupPostSheet(
        groupId: _groupId,
        groupName: widget.group['name'] as String? ?? '',
        onCreated: (post) => reloadPlatform(_load),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final name        = widget.group['name']        as String? ?? 'Grupo';
    final description = widget.group['description'] as String?;
    final team        = widget.group['favoriteTeam'] as String?;
    final members     = widget.group['memberCount']  as int? ?? 0;
    final maxMembers  = widget.group['maxMembers']   as int?;
    final iconB64     = widget.group['icon']         as String?;
    final invitationCode = widget.group['invitationCode']?.toString() ?? widget.group['invitation_code']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(name.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: AppColors.onPrimary, width: 2)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewPost,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.onPrimary, width: 2),
        ),
        child: Icon(Icons.edit_sharp, color: AppColors.onPrimary),
      ),
      body: Column(children: [
        _GroupHeader(
          name: name, description: description, team: team,
          members: members, maxMembers: maxMembers, iconB64: iconB64,
          invitationCode: invitationCode,
        ),
        Expanded(child: _loading
            ? Center(child: CircularProgressIndicator(
                color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.onPrimary,
                backgroundColor: AppColors.primary,
                child: _posts.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _emptyFeed(),
                        )],
                    )
                    : ListView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        itemCount: _posts.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _posts.length) {
                            return Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                            );
                          }
                          final post = _posts[i];
                          return _GroupPostCard(
                            key: ValueKey(post.id),
                            post: post,
                            svc: _svc,
                            onDelete: () => reloadPlatform(_load),
                          );
                        },
                      ),
              ),
        ),
      ]),
    );
  }

  Widget _emptyFeed() => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Icon(Icons.dynamic_feed_sharp, size: 48,
              color: AppColors.textMuted),
        ),
        SizedBox(height: 24),
        Text('AÚN NO HAY PUBLICACIONES.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18)),
        SizedBox(height: 8),
        Text('¡SÉ EL PRIMERO EN PUBLICAR!',
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
      ]),
    ),
  );
}

// ── Group header ──────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String name;
  final String? description, team, iconB64, invitationCode;
  final int members;
  final int? maxMembers;

  const _GroupHeader({
    required this.name, required this.members,
    this.description, this.team, this.iconB64, this.maxMembers, this.invitationCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Icon (Sharp square)
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: iconB64 != null
              ? _b64Image(iconB64!, BoxFit.cover)
              : Center(child: Icon(Icons.groups_sharp, color: AppColors.primary, size: 40)),
        ),
        SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 22,
              fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1, height: 1.1)),
          SizedBox(height: 8),
          if (description != null && description!.isNotEmpty) ...[
            Text(description!, style: GoogleFonts.dmSans(fontSize: 13,
                color: AppColors.textMuted, height: 1.4)),
            SizedBox(height: 12),
          ],
          Wrap(spacing: 16, runSpacing: 8, children: [
            _stat(Icons.people_outline_sharp,
                '$members${maxMembers != null ? '/$maxMembers' : ''} MIEMBROS'),
            if (team != null) _stat(Icons.sports_soccer_sharp, team!.toUpperCase()),
          ]),
          if (invitationCode != null) ...[
            SizedBox(height: 16),
            _CopyCodeButton(code: invitationCode!),
          ],
        ])),
      ]),
    );
  }

  Widget _stat(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.borderLight, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.accentText),
      SizedBox(width: 8),
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.text, letterSpacing: 1)),
    ]),
  );

  Widget _b64Image(String data, BoxFit fit) {
    try {
      final bytes = base64Decode(
          data.contains(',') ? data.split(',').last : data);
      return Image.memory(bytes, fit: fit, width: double.infinity);
    } catch (_) {
      return Container(color: AppColors.onPrimary);
    }
  }
}

class _CopyCodeButton extends StatelessWidget {
  final String code;
  const _CopyCodeButton({required this.code});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CÓDIGO COPIADO AL PORTAPAPELES', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppColors.onPrimary)),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: AppColors.onPrimary, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_sharp, size: 14, color: AppColors.onPrimary),
            SizedBox(width: 8),
            Text(
              'CÓDIGO: $code',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _GroupPostCard extends StatefulWidget {
  final FeedPost post;
  final FeedService svc;
  final VoidCallback onDelete;
  const _GroupPostCard(
      {super.key, required this.post, required this.svc, required this.onDelete});
  @override
  State<_GroupPostCard> createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<_GroupPostCard> {
  late FeedPost _post;
  @override
  void initState() { super.initState(); _post = widget.post; }

  @override
  void didUpdateWidget(_GroupPostCard old) {
    super.didUpdateWidget(old);
    _post = widget.post;
  }

  Future<void> _toggleLike() async {
    final prev = _post.likedByMe;
    setState(() {
      _post.likedByMe = !_post.likedByMe;
      _post.likeCount += _post.likedByMe ? 1 : -1;
    });
    try { await widget.svc.toggleLike(_post.id); }
    catch (_) { setState(() {
      _post.likedByMe = prev;
      _post.likeCount += prev ? 1 : -1;
    }); }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimpleCommentsSheet(
        post: _post, svc: widget.svc,
        onCommentAdded: () => setState(() => _post.commentCount++),
      ),
    );
  }

  void _confirmDelete() {
    final isOwn = AuthService().currentUserId == _post.user.id;
    if (!isOwn) return;
    showDialog(context: context, builder: (dlgCtx) => AlertDialog(
      backgroundColor: AppColors.background,
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
      title: Text('ELIMINAR PUBLICACIÓN',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: AppColors.text)),
      content: Text('¿ESTÁS SEGURO?', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
      actionsPadding: const EdgeInsets.all(24),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(dlgCtx),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            side: BorderSide(color: AppColors.border, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          onPressed: () async {
            Navigator.pop(dlgCtx);
            try {
              await widget.svc.deletePost(_post.id);
              if (mounted) widget.onDelete();
            } catch (_) {}
          },
          child: Text('ELIMINAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = AuthService().currentUserId == _post.user.id;
    final time  = _relativeTime(_post.createdAt).toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _UserAvatar(user: _post.user, radius: 20),
            SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_post.user.displayName.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800,
                      fontSize: 14, color: AppColors.text)),
              Text(time, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold,
                  color: AppColors.textMuted, letterSpacing: 1)),
            ])),
            if (isOwn)
              IconButton(
                icon: Icon(Icons.more_vert_sharp, color: AppColors.textMuted, size: 20),
                onPressed: _confirmDelete,
              ),
          ]),
        ),
        if (_post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(_post.content,
                style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.text,
                    height: 1.5)),
          ),
        if (_post.images.isNotEmpty) ...[
          _PostImages(images: _post.images),
          SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            _ActionBtn(
              icon: _post.likedByMe ? Icons.favorite_sharp : Icons.favorite_border_sharp,
              color: _post.likedByMe ? AppColors.error : AppColors.textMuted,
              label: '${_post.likeCount}', onTap: _toggleLike),
            SizedBox(width: 12),
            _ActionBtn(
              icon: Icons.chat_bubble_outline_sharp,
              color: AppColors.textMuted,
              label: '${_post.commentCount}', onTap: _openComments),
          ]),
        ),
      ]),
    );
  }
}

// ── New post sheet ────────────────────────────────────────────────────────────

class _GroupPostSheet extends StatefulWidget {
  final int groupId;
  final String groupName;
  final void Function(FeedPost) onCreated;
  const _GroupPostSheet(
      {required this.groupId, required this.groupName, required this.onCreated});
  @override
  State<_GroupPostSheet> createState() => _GroupPostSheetState();
}

class _GroupPostSheetState extends State<_GroupPostSheet> {
  final _svc    = FeedService();
  final _ctrl   = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _images = [];
  bool _posting = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    if (_images.length >= 4) return;
    final xf = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 1080);
    if (xf == null) return;
    final b64 = 'data:image/jpeg;base64,${base64Encode(await xf.readAsBytes())}';
    setState(() => _images.add(b64));
  }

  Future<void> _post() async {
    if (_ctrl.text.trim().isEmpty && _images.isEmpty) return;
    setState(() => _posting = true);
    try {
      final post = await _svc.createPost(
          _ctrl.text.trim(), _images, groupId: widget.groupId);
      if (mounted) { widget.onCreated(post); Navigator.pop(context); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(fontWeight: FontWeight.bold))));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final user   = AuthService().currentUser ?? {};
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 4)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 12,
          width: double.infinity,
          color: AppColors.primary,
          child: Center(child: Container(width: 40, height: 4, color: AppColors.onPrimary)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('NUEVA PUBLICACIÓN',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
              Text('EN ${widget.groupName.toUpperCase()}',
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
            ])),
            ElevatedButton(
              onPressed: _posting ? null : _post,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  side: BorderSide(color: AppColors.onPrimary, width: 2)),
              child: _posting
                  ? SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                  : Text('PUBLICAR',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ]),
        ),
        Divider(height: 1, thickness: 2, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _UserAvatar(user: FeedUser(
              id: AuthService().currentUserId ?? 0,
              firstName: user['firstName'] ?? '',
              lastName: user['lastName'] ?? '',
              avatar: user['profilePicture'],
            ), radius: 22),
            SizedBox(width: 16),
            Expanded(child: TextField(
              controller: _ctrl, maxLines: 5, minLines: 2, autofocus: true,
              decoration: InputDecoration(
                hintText: '¿QUÉ ESTÁ PASANDO EN ${widget.groupName.toUpperCase()}?',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none, isDense: true),
              style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.text),
            )),
          ]),
        ),
        if (_images.isNotEmpty)
          SizedBox(height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _images.length + (_images.length < 4 ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (_, i) {
                if (i == _images.length) return _addBtn();
                return Stack(children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
                    child: Image.memory(
                      base64Decode(_images[i].contains(',')
                          ? _images[i].split(',').last : _images[i]),
                      width: 90, height: 90, fit: BoxFit.cover)),
                  Positioned(top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppColors.primary, border: Border.all(color: AppColors.onPrimary, width: 1)),
                        child: Icon(Icons.close_sharp,
                            color: AppColors.onPrimary, size: 12)))),
                ]);
              })),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: _images.isEmpty ? _addBtn() : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _addBtn() => GestureDetector(
    onTap: _pickImage,
    child: Container(width: 100, height: 100,
      decoration: BoxDecoration(color: Colors.transparent,
          border: Border.all(color: AppColors.border, width: 2, style: BorderStyle.solid)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_a_photo_sharp,
            color: AppColors.primary, size: 32),
        SizedBox(height: 8),
        Text('AÑADIR FOTO', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
      ])),
  );
}

// ── Inline comments sheet ─────────────────────────────────────────────────────

class _SimpleCommentsSheet extends StatefulWidget {
  final FeedPost post;
  final FeedService svc;
  final VoidCallback onCommentAdded;
  const _SimpleCommentsSheet(
      {required this.post, required this.svc, required this.onCommentAdded});
  @override
  State<_SimpleCommentsSheet> createState() => _SimpleCommentsSheetState();
}

class _SimpleCommentsSheetState extends State<_SimpleCommentsSheet> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  List<FeedComment> _comments = [];
  bool _loading = true;
  FeedComment? _replyingTo;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final c = await widget.svc.getComments(widget.post.id);
      if (mounted) setState(() { _comments = c; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear(); _focus.unfocus();
    try {
      final comment = await widget.svc.addComment(
          widget.post.id, text, parentId: _replyingTo?.id);
      if (mounted) {
        setState(() {
          if (_replyingTo != null) {
            final idx = _comments.indexWhere((c) => c.id == _replyingTo!.id);
            if (idx >= 0) _comments[idx].replies.add(comment);
          } else { _comments.add(comment); }
          _replyingTo = null;
        });
        widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().toUpperCase())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 4)),
      ),
      child: Column(children: [
        Container(
          height: 12,
          width: double.infinity,
          color: AppColors.primary,
          child: Center(child: Container(width: 40, height: 4, color: AppColors.onPrimary)),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(children: [
            Text('COMENTARIOS',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.text, border: Border.all(color: AppColors.onPrimary, width: 1)),
              child: Text('${widget.post.commentCount}',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.onPrimary, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ])),
        Divider(height: 1, thickness: 2, color: AppColors.border),
        Flexible(child: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.text))
          : _comments.isEmpty
            ? Padding(padding: const EdgeInsets.all(48),
                child: Text('SIN COMENTARIOS AÚN.',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _comments.length,
                itemBuilder: (_, i) => _CommentRow(
                  comment: _comments[i], svc: widget.svc,
                  onReply: (c) { setState(() => _replyingTo = c);
                    _focus.requestFocus(); }),
              )),
        if (_replyingTo != null)
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              Icon(Icons.reply_sharp, size: 16, color: AppColors.onPrimary),
              SizedBox(width: 12),
              Expanded(child: Text(
                'RESPONDIENDO A ${_replyingTo!.user.displayName.toUpperCase()}',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.onPrimary,
                    fontWeight: FontWeight.w900, letterSpacing: 1))),
              GestureDetector(onTap: () => setState(() => _replyingTo = null),
                child: Icon(Icons.close_sharp, size: 16, color: AppColors.onPrimary)),
            ]),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 2))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl, focusNode: _focus, maxLines: null,
              onSubmitted: (_) => _submit(),
              style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: _replyingTo != null ? 'RESPONDER...' : 'AÑADIR COMENTARIO...',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.primary, width: 2)),
              ),
            )),
            SizedBox(width: 12),
            GestureDetector(onTap: _submit,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppColors.primary, border: Border.all(color: AppColors.onPrimary, width: 2)),
                child: Icon(Icons.send_sharp, color: AppColors.onPrimary, size: 22))),
          ]),
        ),
      ]),
    );
  }
}

class _CommentRow extends StatefulWidget {
  final FeedComment comment;
  final FeedService svc;
  final void Function(FeedComment) onReply;
  const _CommentRow(
      {required this.comment, required this.svc, required this.onReply});
  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  bool _showReplies = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _tile(widget.comment, 0),
    if (widget.comment.replies.isNotEmpty) ...[
      Padding(padding: const EdgeInsets.only(left: 68, bottom: 8),
        child: GestureDetector(
          onTap: () => setState(() => _showReplies = !_showReplies),
          child: Text(
              _showReplies ? 'OCULTAR RESPUESTAS'
                  : 'VER ${widget.comment.replies.length} RESPUESTA(S)',
              style: GoogleFonts.dmSans(fontSize: 10,
                  color: AppColors.accentText, fontWeight: FontWeight.w900, letterSpacing: 1)))),
      if (_showReplies)
        ...widget.comment.replies.map((r) => _tile(r, 48)),
    ],
  ]);

  Widget _tile(FeedComment c, double indent) => Padding(
    padding: EdgeInsets.fromLTRB(20 + indent, 8, 20, 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _UserAvatar(user: c.user, radius: 16),
      SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.user.displayName.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text)),
          SizedBox(width: 10),
          Text(_relativeTime(c.createdAt).toUpperCase(),
              style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
        SizedBox(height: 4),
        Text(c.content, style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: AppColors.text)),
        SizedBox(height: 8),
        Row(children: [
          GestureDetector(
            onTap: () async {
              final prev = c.likedByMe;
              setState(() {
                c.likedByMe = !c.likedByMe;
                c.likeCount += c.likedByMe ? 1 : -1;
              });
              try { await widget.svc.toggleCommentLike(c.id); }
              catch (_) { setState(() {
                c.likedByMe = prev; c.likeCount += prev ? 1 : -1;
              }); }
            },
            child: Row(children: [
              Icon(c.likedByMe ? Icons.favorite_sharp : Icons.favorite_border_sharp,
                  size: 14,
                  color: c.likedByMe ? AppColors.error : AppColors.textMuted),
              if (c.likeCount > 0) ...[
                SizedBox(width: 6),
                Text('${c.likeCount}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
              ],
            ]),
          ),
          if (indent == 0) ...[
            SizedBox(width: 24),
            GestureDetector(
              onTap: () => widget.onReply(c),
              child: Text('RESPONDER',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.accentText,
                      fontWeight: FontWeight.w900, letterSpacing: 1))),
          ],
        ]),
      ])),
    ]),
  );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final FeedUser user;
  final double radius;
  const _UserAvatar({required this.user, required this.radius});
  @override
  Widget build(BuildContext context) {
    final avatar = user.avatar;
    ImageProvider? img;
    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('data:image') || avatar.length > 200) {
        try {
          final b64 = avatar.contains(',') ? avatar.split(',').last : avatar;
          img = MemoryImage(base64Decode(b64));
        } catch (_) {}
      } else if (avatar.startsWith('http')) {
        img = NetworkImage(avatar);
      }
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border.all(color: AppColors.onPrimary, width: 2),
      ),
      child: img != null
          ? Image(image: img, fit: BoxFit.cover)
          : Center(child: Text(user.initials, style: GoogleFonts.spaceGrotesk(color: AppColors.onPrimary,
              fontSize: radius * 0.8, fontWeight: FontWeight.w900))),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final String label; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color,
      required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 8),
          Text(label, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 13,
              fontWeight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _PostImages extends StatelessWidget {
  final List<String> images;
  const _PostImages({required this.images});
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    if (images.length == 1) return _img(images[0], sw, 300);
    return SizedBox(height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
          child: _img(images[i], sw * 0.75, 220)),
      ));
  }

  Widget _img(String data, double w, double h) {
    final isB64 = data.startsWith('data:image') || data.length > 200;
    Widget img;
    if (isB64) {
      try {
        final bytes = base64Decode(
            data.contains(',') ? data.split(',').last : data);
        img = Image.memory(bytes, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _ph(w, h));
      } catch (_) { return _ph(w, h); }
    } else {
      img = Image.network(data, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _ph(w, h));
    }
    return Container(
      width: w, height: h,
      color: AppColors.background,
      child: Center(child: img),
    );
  }

  Widget _ph(double w, double h) => Container(width: w, height: h,
    constraints: BoxConstraints(minHeight: 100),
    color: AppColors.background,
    child: Center(child: Icon(Icons.broken_image_sharp, color: AppColors.border, size: 32)));
}

String _relativeTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'ahora';
    if (diff.inMinutes < 60)  return 'hace ${diff.inMinutes} min';
    if (diff.inHours   < 24)  return 'hace ${diff.inHours} h';
    if (diff.inDays    < 7)   return 'hace ${diff.inDays} d';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) { return ''; }
}

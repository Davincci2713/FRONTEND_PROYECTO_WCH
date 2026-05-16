import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/feed_service.dart';
import '../services/auth/auth.dart';

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

  int get _groupId => widget.group['idCommunity'] as int;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        !_loadingMore && _hasMore) _loadMore();
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
        onCreated: (post) => setState(() => _posts.insert(0, post)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name        = widget.group['name']        as String? ?? 'Grupo';
    final description = widget.group['description'] as String?;
    final team        = widget.group['favoriteTeam'] as String?;
    final members     = widget.group['memberCount']  as int? ?? 0;
    final maxMembers  = widget.group['maxMembers']   as int?;
    final bannerB64   = widget.group['banner']       as String?;
    final iconB64     = widget.group['icon']         as String?;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: const Color(0xFF00341C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewPost,
        backgroundColor: const Color(0xFF00341C),
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit_outlined),
      ),
      body: Column(children: [
        _GroupHeader(
          name: name, description: description, team: team,
          members: members, maxMembers: maxMembers, iconB64: iconB64,
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: Color(0xFF00341C)))
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF00341C),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _posts.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(
                                  color: Color(0xFF00341C))),
                            );
                          }
                          return _GroupPostCard(
                            post: _posts[i],
                            svc: _svc,
                            onDelete: () =>
                                setState(() => _posts.removeAt(i)),
                          );
                        },
                      ),
              ),
        ),
      ]),
    );
  }

  Widget _emptyFeed() => ListView(children: [
    Padding(
      padding: const EdgeInsets.all(48),
      child: Column(children: [
        Icon(Icons.dynamic_feed_outlined, size: 56,
            color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Aún no hay publicaciones en este grupo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        const SizedBox(height: 8),
        Text('¡Sé el primero en publicar!',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    ),
  ]);
}

// ── Banner full image ─────────────────────────────────────────────────────────

class _BannerImage extends StatelessWidget {
  final String b64;
  const _BannerImage({required this.b64});
  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(b64.contains(',') ? b64.split(',').last : b64);
      return Image.memory(bytes, fit: BoxFit.contain,
          width: double.infinity, color: Colors.black.withValues(alpha: 0.1),
          colorBlendMode: BlendMode.darken);
    } catch (_) {
      return Container(color: const Color(0xFF00341C));
    }
  }
}

// ── Group header ──────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String name;
  final String? description, team, iconB64;
  final int members;
  final int? maxMembers;

  const _GroupHeader({
    required this.name, required this.members,
    this.description, this.team, this.iconB64, this.maxMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Icon
        Container(
          width: 64, height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00341C).withValues(alpha: 0.1),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8)],
          ),
          child: iconB64 != null
              ? _b64Image(iconB64!, BoxFit.cover)
              : const Icon(Icons.group, color: Color(0xFF00341C), size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 4),
          if (description != null && description!.isNotEmpty) ...[
            Text(description!, style: TextStyle(fontSize: 13,
                color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 8),
          ],
          Wrap(spacing: 16, children: [
            _stat(Icons.people_outline,
                '$members${maxMembers != null ? '/$maxMembers' : ''} miembros'),
            if (team != null) _stat(Icons.sports_soccer, team!),
          ]),
        ])),
      ]),
    );
  }

  Widget _stat(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: Colors.grey.shade500),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
  ]);

  Widget _b64Image(String data, BoxFit fit) {
    try {
      final bytes = base64Decode(
          data.contains(',') ? data.split(',').last : data);
      return Image.memory(bytes, fit: fit, width: double.infinity);
    } catch (_) {
      return Container(color: Colors.grey.shade100);
    }
  }
}

// ── Post card (reuses same layout as global feed) ─────────────────────────────

class _GroupPostCard extends StatefulWidget {
  final FeedPost post;
  final FeedService svc;
  final VoidCallback onDelete;
  const _GroupPostCard(
      {required this.post, required this.svc, required this.onDelete});
  @override
  State<_GroupPostCard> createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<_GroupPostCard> {
  late FeedPost _post;
  @override
  void initState() { super.initState(); _post = widget.post; }

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Eliminar publicación',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: const Text('¿Estás seguro?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white, elevation: 0),
          onPressed: () async {
            Navigator.pop(dlgCtx);
            try {
              await widget.svc.deletePost(_post.id);
              if (mounted) widget.onDelete();
            } catch (_) {}
          },
          child: const Text('Eliminar'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = AuthService().currentUserId == _post.user.id;
    final time  = _relativeTime(_post.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
          child: Row(children: [
            _UserAvatar(user: _post.user, radius: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_post.user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 14, color: Colors.black87)),
              Text(time, style: TextStyle(fontSize: 11,
                  color: Colors.grey.shade500)),
            ])),
            if (isOwn)
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 20),
                onPressed: _confirmDelete,
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
          ]),
        ),
        if (_post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(_post.content,
                style: const TextStyle(fontSize: 14, color: Colors.black87,
                    height: 1.45)),
          ),
        if (_post.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          _PostImages(images: _post.images),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(children: [
            _ActionBtn(
              icon: _post.likedByMe ? Icons.favorite : Icons.favorite_border,
              color: _post.likedByMe ? Colors.red.shade500 : Colors.grey.shade600,
              label: '${_post.likeCount}', onTap: _toggleLike),
            const SizedBox(width: 4),
            _ActionBtn(
              icon: Icons.chat_bubble_outline,
              color: Colors.grey.shade600,
              label: '${_post.commentCount}', onTap: _openComments),
          ]),
        ),
      ]),
    );
  }
}

// ── New post sheet for group ──────────────────────────────────────────────────

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
  List<String> _images = [];
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
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('Nueva publicación',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text('en ${widget.groupName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ])),
            ElevatedButton(
              onPressed: _posting ? null : _post,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00341C),
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: _posting
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Publicar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _UserAvatar(user: FeedUser(
              id: AuthService().currentUserId ?? 0,
              firstName: user['firstName'] ?? '',
              lastName: user['lastName'] ?? '',
              avatar: user['profilePicture'],
            ), radius: 18),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: _ctrl, maxLines: 5, minLines: 2, autofocus: true,
              decoration: InputDecoration(
                hintText: '¿Qué está pasando en ${widget.groupName}?',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none, isDense: true),
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            )),
          ]),
        ),
        if (_images.isNotEmpty)
          SizedBox(height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _images.length + (_images.length < 4 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == _images.length) return _addBtn();
                return Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(_images[i].contains(',')
                          ? _images[i].split(',').last : _images[i]),
                      width: 80, height: 80, fit: BoxFit.cover)),
                  Positioned(top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 12)))),
                ]);
              })),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _addBtn(),
        ),
      ]),
    );
  }

  Widget _addBtn() => GestureDetector(
    onTap: _pickImage,
    child: Container(width: 80, height: 80,
      decoration: BoxDecoration(color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1.5)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined,
            color: Colors.grey.shade500, size: 28),
        const SizedBox(height: 4),
        Text('Foto', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            const Text('Comentarios',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            Text('${widget.post.commentCount}',
                style: TextStyle(color: Colors.grey.shade500)),
          ])),
        Divider(height: 1, color: Colors.grey.shade200),
        Flexible(child: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF00341C)))
          : _comments.isEmpty
            ? Padding(padding: const EdgeInsets.all(32),
                child: Text('Sin comentarios aún.',
                    style: TextStyle(color: Colors.grey.shade500)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _comments.length,
                itemBuilder: (_, i) => _CommentRow(
                  comment: _comments[i], svc: widget.svc,
                  onReply: (c) { setState(() => _replyingTo = c);
                    _focus.requestFocus(); }),
              )),
        if (_replyingTo != null)
          Container(
            color: const Color(0xFF00341C).withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.reply, size: 16, color: const Color(0xFF00341C)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Respondiendo a ${_replyingTo!.user.displayName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF00341C),
                    fontWeight: FontWeight.w500))),
              GestureDetector(onTap: () => setState(() => _replyingTo = null),
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade600)),
            ]),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl, focusNode: _focus, maxLines: null,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: _replyingTo != null ? 'Responder...' : 'Comentar...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: Color(0xFF00341C))),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(onTap: _submit,
              child: Container(padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Color(0xFF00341C), shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 18))),
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
      Padding(padding: const EdgeInsets.only(left: 56),
        child: GestureDetector(
          onTap: () => setState(() => _showReplies = !_showReplies),
          child: Padding(padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _showReplies ? 'Ocultar respuestas'
                  : 'Ver ${widget.comment.replies.length} respuesta(s)',
              style: const TextStyle(fontSize: 12,
                  color: Color(0xFF00341C), fontWeight: FontWeight.w600))))),
      if (_showReplies)
        ...widget.comment.replies.map((r) => _tile(r, 40)),
    ],
  ]);

  Widget _tile(FeedComment c, double indent) => Padding(
    padding: EdgeInsets.fromLTRB(16 + indent, 8, 16, 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _UserAvatar(user: c.user, radius: 14),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 6),
          Text(_relativeTime(c.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 2),
        Text(c.content, style: const TextStyle(fontSize: 13, height: 1.4)),
        const SizedBox(height: 4),
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
              Icon(c.likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 14,
                  color: c.likedByMe ? Colors.red.shade500 : Colors.grey.shade500),
              if (c.likeCount > 0) ...[
                const SizedBox(width: 3),
                Text('${c.likeCount}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ]),
          ),
          if (indent == 0) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => widget.onReply(c),
              child: Text('Responder',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500))),
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
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF00341C),
      backgroundImage: img,
      child: img == null
          ? Text(user.initials, style: TextStyle(color: Colors.white,
              fontSize: radius * 0.7, fontWeight: FontWeight.w600))
          : null,
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final String label; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color,
      required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18, color: color),
    label: Text(label, style: TextStyle(color: color, fontSize: 13,
        fontWeight: FontWeight.w500)),
    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
  );
}

class _PostImages extends StatelessWidget {
  final List<String> images;
  const _PostImages({required this.images});
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    if (images.length == 1) return _img(images[0], sw, 300);
    return SizedBox(height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _img(images[i], sw * 0.65, 200)),
      ));
  }

  Widget _img(String data, double w, double h) {
    final isB64 = data.startsWith('data:image') || data.length > 200;
    if (isB64) {
      try {
        final bytes = base64Decode(
            data.contains(',') ? data.split(',').last : data);
        return Image.memory(bytes, width: w, height: h, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _ph(w, h));
      } catch (_) { return _ph(w, h); }
    }
    return Image.network(data, width: w, height: h, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _ph(w, h));
  }

  Widget _ph(double w, double h) => Container(width: w, height: h,
    color: Colors.grey.shade100,
    child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400));
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

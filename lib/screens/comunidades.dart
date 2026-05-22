import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import 'package:frontend_proyecto/services/community_service.dart';
import 'package:frontend_proyecto/services/feed_service.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:frontend_proyecto/utils/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class ComunidadesScreen extends StatelessWidget {
  const ComunidadesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: TabBar(
              labelColor: AppColors.accentText,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.accentText,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
              tabs: const [
                Tab(icon: Icon(Icons.dynamic_feed_rounded, size: 20), text: 'FEED'),
                Tab(icon: Icon(Icons.groups_rounded, size: 20), text: 'MIS GRUPOS'),
              ],
            ),
          ),
        ),
        body: const TabBarView(children: [_FeedTab(), _GruposTab()]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed tab
// ─────────────────────────────────────────────────────────────────────────────

class _FeedTab extends StatefulWidget {
  const _FeedTab();
  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> with AutomaticKeepAliveClientMixin {
  final _svc    = FeedService();
  final _scroll = ScrollController();
  List<FeedPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _page = 1; _hasMore = true; });
    try {
      final posts = await _svc.getFeed(page: 1);
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
      final more = await _svc.getFeed(page: _page + 1);
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

  void _openNewPost() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewPostSheet(onCreated: (post) {
        setState(() => _posts.insert(0, post));
      }),
    );
    if (ok == true) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewPost,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.onPrimary, width: 2)),
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.text))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.onPrimary,
              backgroundColor: AppColors.primary,
              child: _posts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _emptyFeed(),
                      )],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                      itemCount: _posts.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _posts.length) {
                          return Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(
                                color: AppColors.primary)),
                          );
                        }
                        return _PostCard(
                          post: _posts[i],
                          onDelete: () => setState(() => _posts.removeAt(i)),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _emptyFeed() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
        child: Icon(Icons.dynamic_feed_outlined, size: 48, color: AppColors.textMuted),
      ),
      SizedBox(height: 24),
      Text('EL FEED ESTÁ VACÍO', style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
      SizedBox(height: 8),
      Text('SÉ EL PRIMERO EN COMPARTIR ALGO',
          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Post card
// ─────────────────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final FeedPost post;
  final VoidCallback onDelete;
  const _PostCard({required this.post, required this.onDelete});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final _svc = FeedService();
  late FeedPost _post;

  @override
  void initState() { super.initState(); _post = widget.post; }

  Future<void> _toggleLike() async {
    final prev = _post.likedByMe;
    setState(() {
      _post.likedByMe = !_post.likedByMe;
      _post.likeCount += _post.likedByMe ? 1 : -1;
    });
    try {
      await _svc.toggleLike(_post.id);
    } catch (_) {
      setState(() { _post.likedByMe = prev; _post.likeCount += prev ? 1 : -1; });
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: _post,
        onCommentAdded: () => setState(() => _post.commentCount++),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
      builder: (sheetCtx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: AppColors.border)),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: AppColors.text),
            title: Text('EDITAR PUBLICACIÓN',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: AppColors.text, fontSize: 16)),
            onTap: () { Navigator.pop(sheetCtx); _openEdit(); },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.error),
            title: Text('ELIMINAR PUBLICACIÓN',
                style: GoogleFonts.spaceGrotesk(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 16)),
            onTap: () { Navigator.pop(sheetCtx); _confirmDelete(); },
          ),
          SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _openEdit() {
    final ctrl = TextEditingController(text: _post.content);
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
        title: Text('EDITAR PUBLICACIÓN', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
        content: TextField(
          controller: ctrl, maxLines: 6, minLines: 2, autofocus: true,
          style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: '¿QUÉ ESTÁ PASANDO EN EL MUNDIAL?',
            hintStyle: GoogleFonts.dmSans(color: AppColors.border),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dlgCtx),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.border, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            onPressed: () async {
              final newContent = ctrl.text.trim();
              Navigator.pop(dlgCtx);
              try {
                final updated = await _svc.editPost(_post.id, newContent);
                if (mounted) setState(() => _post.content = updated.content);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: Text('GUARDAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
        title: Text('ELIMINAR PUBLICACIÓN', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
        content: Text('¿ESTÁS SEGURO? ESTA ACCIÓN NO SE PUEDE DESHACER.', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dlgCtx),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.border, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.inverseSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              try {
                await _svc.deletePost(_post.id);
                if (mounted) widget.onDelete();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: Text('ELIMINAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = AuthService().currentUserId == _post.user.id;
    final time  = _formatTime(_post.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
          child: Row(children: [
            _Avatar(user: _post.user, radius: 24),
            SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_post.user.displayName.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900,
                        fontSize: 16, color: AppColors.text, letterSpacing: -0.5)),
                Text(time, style: GoogleFonts.dmSans(fontSize: 10,
                    color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ])),
            if (isOwn)
              IconButton(
                icon: Icon(Icons.more_vert, color: AppColors.textMuted, size: 24),
                onPressed: _showOptions,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ]),
        ),

        // Content
        if (_post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(_post.content,
                style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.text,
                    height: 1.5)),
          ),

        // Images
        if (_post.images.isNotEmpty) ...[
          SizedBox(height: 16),
          _ImageGrid(images: _post.images),
          SizedBox(height: 16),
        ],

        Divider(height: 2, color: AppColors.border),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _ActionButton(
              icon: _post.likedByMe ? Icons.favorite : Icons.favorite_border,
              color: _post.likedByMe ? AppColors.error : AppColors.textMuted,
              label: '${_post.likeCount}',
              onTap: _toggleLike,
            ),
            SizedBox(width: 16),
            _ActionButton(
              icon: Icons.chat_bubble_outline,
              color: AppColors.textMuted,
              label: '${_post.commentCount}',
              onTap: _openComments,
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image grid (1-4 images)
// ─────────────────────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<String> images;
  const _ImageGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    if (images.length == 1) {
      return Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 2), bottom: BorderSide(color: AppColors.border, width: 2))),
        child: _FullImage(data: images[0], maxWidth: screenW)
      );
    }
    // Multiple images: horizontal scroll, each shown complete
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: images.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(right: e.key < images.length - 1 ? 16 : 0),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: screenW * 0.72, maxHeight: 360),
              child: _FullImage(data: e.value, maxWidth: screenW * 0.72),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  final String data;
  final double maxWidth;
  const _FullImage({required this.data, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final isBase64 = data.startsWith('data:image') || data.length > 200;
    Widget img;
    if (isBase64) {
      try {
        final bytes = base64Decode(data.contains(',') ? data.split(',').last : data);
        img = Image.memory(bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _placeholder());
      } catch (_) {
        return _placeholder();
      }
    } else {
      img = Image.network(data,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder());
    }

    return Container(
      color: AppColors.background,
      constraints: BoxConstraints(
        maxWidth: maxWidth, 
        maxHeight: 480,
        minHeight: 120,
      ),
      child: Center(child: img),
    );
  }

  Widget _placeholder() => Container(
    width: maxWidth, height: 120,
    color: AppColors.background,
    child: Icon(Icons.broken_image_outlined,
        color: AppColors.border, size: 48));
}

// ─────────────────────────────────────────────────────────────────────────────
// Comments bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final FeedPost post;
  final VoidCallback onCommentAdded;
  const _CommentsSheet({required this.post, required this.onCommentAdded});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _svc   = FeedService();
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  List<FeedComment> _comments = [];
  bool _loading = true;
  FeedComment? _replyingTo;

  @override
  void initState() { super.initState(); _loadComments(); }

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  Future<void> _loadComments() async {
    try {
      final c = await _svc.getComments(widget.post.id);
      if (mounted) setState(() { _comments = c; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    _focus.unfocus();
    try {
      final comment = await _svc.addComment(
        widget.post.id, text, parentId: _replyingTo?.id);
      if (mounted) {
        setState(() {
          if (_replyingTo != null) {
            final idx = _comments.indexWhere((c) => c.id == _replyingTo!.id);
            if (idx >= 0) _comments[idx].replies.add(comment);
          } else {
            _comments.add(comment);
          }
          _replyingTo = null;
        });
        widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(children: [
        // Handle
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border))),
        // Title
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(children: [
            Text('COMENTARIOS',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.text, letterSpacing: -1)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: AppColors.border, width: 2)),
              child: Text('${widget.post.commentCount}',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ])),
        Divider(height: 2, color: AppColors.border),

        // List
        Flexible(child: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.text))
          : _comments.isEmpty
            ? Padding(padding: const EdgeInsets.all(48),
                child: Text('SIN COMENTARIOS AÚN.\n¡SÉ EL PRIMERO!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _comments.length,
                separatorBuilder: (_, __) => Divider(color: AppColors.borderLight, indent: 64),
                itemBuilder: (_, i) => _CommentTile(
                  comment: _comments[i],
                  svc: _svc,
                  onReply: (c) {
                    setState(() => _replyingTo = c);
                    _focus.requestFocus();
                  },
                ),
              ),
        ),

        // Reply indicator
        if (_replyingTo != null)
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(children: [
              Icon(Icons.reply, size: 20, color: AppColors.onPrimary),
              SizedBox(width: 12),
              Expanded(child: Text(
                'RESPONDIENDO A ${_replyingTo!.user.displayName.toUpperCase()}',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold, letterSpacing: 1))),
              GestureDetector(
                onTap: () => setState(() => _replyingTo = null),
                child: Icon(Icons.close, size: 20, color: AppColors.onPrimary)),
            ]),
          ),

        // Input
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Row(children: [
            _Avatar(user: FeedUser(
              id: AuthService().currentUserId ?? 0,
              firstName: AuthService().currentUser?['firstName'] ?? '',
              lastName:  AuthService().currentUser?['lastName'] ?? '',
            ), radius: 24),
            SizedBox(width: 16),
            Expanded(child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: _replyingTo != null ? 'RESPONDER...' : 'AÑADIR COMENTARIO...',
                hintStyle: GoogleFonts.dmSans(color: AppColors.border, fontSize: 14),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border, width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border, width: 2)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.primary, width: 2)),
              ),
            )),
            SizedBox(width: 12),
            GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.primary, border: Border.all(color: AppColors.onPrimary, width: 2)),
                child: Icon(Icons.send, color: AppColors.onPrimary, size: 24),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment tile (with replies)
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends StatefulWidget {
  final FeedComment comment;
  final FeedService svc;
  final void Function(FeedComment) onReply;
  const _CommentTile({required this.comment, required this.svc,
      required this.onReply});
  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;

  Future<void> _toggleLike() async {
    final prev = widget.comment.likedByMe;
    setState(() {
      widget.comment.likedByMe = !widget.comment.likedByMe;
      widget.comment.likeCount += widget.comment.likedByMe ? 1 : -1;
    });
    try {
      await widget.svc.toggleCommentLike(widget.comment.id);
    } catch (_) {
      setState(() {
        widget.comment.likedByMe = prev;
        widget.comment.likeCount += prev ? 1 : -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildComment(widget.comment, indent: 0),
      if (widget.comment.replies.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(left: 64),
          child: GestureDetector(
            onTap: () => setState(() => _showReplies = !_showReplies),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 1)),
                child: Text(
                  _showReplies
                      ? 'OCULTAR RESPUESTAS'
                      : 'VER ${widget.comment.replies.length} RESPUESTA(S)',
                  style: GoogleFonts.spaceGrotesk(fontSize: 10,
                      color: AppColors.accentText, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ),
        if (_showReplies)
          ...widget.comment.replies.map((r) => _buildComment(r, indent: 40)),
      ],
    ],
  );

  Widget _buildComment(FeedComment c, {required double indent}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24 + indent, 12, 24, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(user: c.user, radius: 16),
        SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(c.user.displayName.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900,
                      fontSize: 14, color: AppColors.text)),
              SizedBox(width: 12),
              Text(_formatTime(c.createdAt),
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]),
            SizedBox(height: 8),
            Text(c.content,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted,
                    height: 1.4)),
            SizedBox(height: 12),
            Row(children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(children: [
                  Icon(
                    c.likedByMe ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: c.likedByMe ? AppColors.error : AppColors.textMuted,
                  ),
                  if (c.likeCount > 0) ...[
                    SizedBox(width: 6),
                    Text('${c.likeCount}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900,
                            color: AppColors.textMuted)),
                  ],
                ]),
              ),
              SizedBox(width: 24),
              if (indent == 0)
                GestureDetector(
                  onTap: () => widget.onReply(c),
                  child: Text('RESPONDER',
                      style: GoogleFonts.dmSans(fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
            ]),
          ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New post bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NewPostSheet extends StatefulWidget {
  final void Function(FeedPost) onCreated;
  const _NewPostSheet({required this.onCreated});
  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _svc     = FeedService();
  final _ctrl    = TextEditingController();
  final _picker  = ImagePicker();
  final List<String> _images = [];
  bool _posting = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    if (_images.length >= 4) return;
    final xf = await _picker.pickImage(source: ImageSource.gallery,
        imageQuality: 75, maxWidth: 1080);
    if (xf == null) return;
    final bytes = await xf.readAsBytes();
    final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    setState(() => _images.add(b64));
  }

  Future<void> _post() async {
    if (_ctrl.text.trim().isEmpty && _images.isEmpty) return;
    setState(() => _posting = true);
    try {
      final post = await _svc.createPost(_ctrl.text.trim(), _images);
      if (mounted) {
        widget.onCreated(post);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle + header
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border))),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(children: [
            Text('NUEVA PUBLICACIÓN',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
            const Spacer(),
            ElevatedButton(
              onPressed: _posting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
              child: _posting
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppColors.onPrimary,
                          strokeWidth: 3))
                  : Text('PUBLICAR',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ]),
        ),
        Divider(height: 2, color: AppColors.border),

        // Text input
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Avatar(user: FeedUser(
              id: AuthService().currentUserId ?? 0,
              firstName: user['firstName'] ?? '',
              lastName: user['lastName'] ?? '',
              avatar: user['profilePicture'],
            ), radius: 24),
            SizedBox(width: 16),
            Expanded(child: TextField(
              controller: _ctrl,
              maxLines: 5,
              minLines: 2,
              autofocus: true,
              style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 18),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: '¿QUÉ ESTÁ PASANDO EN EL MUNDIAL?',
                hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.border, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )),
          ]),
        ),

        // Image previews
        if (_images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _images.length + (_images.length < 4 ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(width: 16),
              itemBuilder: (_, i) {
                if (i == _images.length) return _addImageBtn();
                return Stack(children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
                    child: Image.memory(
                      base64Decode(_images[i].contains(',')
                          ? _images[i].split(',').last : _images[i]),
                      width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  Positioned(top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: AppColors.onPrimary, border: Border.all(color: AppColors.text, width: 2)),
                        child: Icon(Icons.close,
                            color: AppColors.text, size: 16)),
                    )),
                ]);
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [_addImageBtn()]),
          ),

        SizedBox(height: 32),
      ]),
    );
  }

  Widget _addImageBtn() => GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined,
            color: AppColors.textMuted, size: 32),
        SizedBox(height: 8),
        Text('FOTO', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900,
            color: AppColors.textMuted)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Mis grupos tab (existing community functionality)
// ─────────────────────────────────────────────────────────────────────────────

class _GruposTab extends StatefulWidget {
  const _GruposTab();
  @override
  State<_GruposTab> createState() => _GruposTabState();
}

class _GruposTabState extends State<_GruposTab> {
  final _svc = CommunityService();
  int get _userId => AuthService().currentUserId ?? 1;

  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _suggested = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.getMyCommunities(_userId),
        _svc.getSuggestedCommunities(_userId),
      ]);
      if (mounted) {
        setState(() {
        _mine      = results[0];
        _suggested = results[1];
        _loading   = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateGroupSheet(
        userId: _userId, svc: _svc,
        onCreated: (code) { _showCode(code); _load(); },
      ),
    );
  }

  void _showJoin() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (dlgCtx) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
      title: Text('UNIRSE CON CÓDIGO',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number,
        style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
        textAlign: TextAlign.center,
        cursorColor: AppColors.primary,
        decoration: const InputDecoration(hintText: '000000')),
      actionsPadding: const EdgeInsets.all(24),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(dlgCtx),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.border, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          onPressed: () async {
            try {
              await _svc.joinCommunity(int.parse(ctrl.text), _userId);
              if (!mounted) return;
              Navigator.pop(dlgCtx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('¡TE UNISTE!', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary));
              _load();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
              }
            }
          },
          child: Text('UNIRSE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
        ),
      ],
    ));
  }

  void _showCode(String code) {
    showDialog(context: context, builder: (dlgCtx) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
      title: Text('GRUPO CREADO', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.accentText, letterSpacing: -1)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('COMPARTE ESTE CÓDIGO CON TUS AMIGOS:',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.primary, width: 2)),
          child: Text(code, style: GoogleFonts.spaceGrotesk(fontSize: 48,
              fontWeight: FontWeight.w900, letterSpacing: 4,
              color: AppColors.text)),
        ),
      ]),
      actionsPadding: const EdgeInsets.all(24),
      actions: [OutlinedButton(onPressed: () => Navigator.pop(dlgCtx),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text('CERRAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)))],
    ));
  }

  Future<void> _joinSuggested(Map<String, dynamic> group) async {
    final code = int.tryParse(group['invitationCode'].toString());
    if (code == null) return;
    try {
      await _svc.joinCommunity(code, _userId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('¡TE UNISTE A ${group['name'].toString().toUpperCase()}!', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.onPrimary,
      backgroundColor: AppColors.primary,
      child: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.text))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Acciones
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: _showCreate,
                    icon: Icon(Icons.add, size: 20),
                    label: Text('CREAR GRUPO'),
                  )),
                  SizedBox(width: 16),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _showJoin,
                    icon: Icon(Icons.group_add, size: 20),
                    label: Text('UNIRME'),
                  )),
                ]),
                SizedBox(height: 48),

                // Mis grupos
                _sectionHeader('MIS GRUPOS', '${_mine.length}'),
                SizedBox(height: 24),
                if (_mine.isEmpty)
                  _emptyState(
                    icon: Icons.groups_rounded,
                    message: 'AÚN NO PERTENECES A NINGÚN GRUPO.',
                    sub: 'CREA UNO O ÚNETE CON UN CÓDIGO.',
                  )
                else
                  _groupGrid(_mine, isMine: true),

                SizedBox(height: 48),

                // Grupos sugeridos
                _sectionHeader('GRUPOS SUGERIDOS', null),
                SizedBox(height: 24),
                if (_suggested.isEmpty)
                  _emptyState(
                    icon: Icons.explore_rounded,
                    message: 'NO HAY GRUPOS SUGERIDOS DISPONIBLES.',
                  )
                else
                  _groupGrid(_suggested, isMine: false),
              ]),
            ),
    );
  }

  Widget _groupGrid(List<Map<String, dynamic>> groups, {required bool isMine}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 220,
      ),
      itemCount: groups.length,
      itemBuilder: (_, i) => _CommunityCard(
        group: groups[i],
        isMine: isMine,
        onJoin: isMine ? null : () => _joinSuggested(groups[i]),
      ),
    );
  }

  Widget _sectionHeader(String title, String? count) => Row(children: [
    Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 24,
        fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1)),
    if (count != null) ...[
      SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: AppColors.onPrimary, width: 2),
        ),
        child: Text(count, style: GoogleFonts.spaceGrotesk(fontSize: 16,
            color: AppColors.onPrimary, fontWeight: FontWeight.w900)),
      ),
    ],
  ]);

  Widget _emptyState({required IconData icon, required String message, String? sub}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: Colors.transparent,
          border: Border.all(color: AppColors.border, width: 2)),
      child: Column(children: [
        Icon(icon, size: 48, color: AppColors.border),
        SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        if (sub != null) ...[
          SizedBox(height: 8),
          Text(sub, textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ]),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Community card
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isMine;
  final VoidCallback? onJoin;
  const _CommunityCard({required this.group, required this.isMine, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final name        = group['name']          as String? ?? 'SIN NOMBRE';
    final description = group['description']  as String?;
    final team        = group['favoriteTeam'] as String?;
    final members     = group['memberCount']  as int?    ?? 0;
    final maxMembers  = group['maxMembers']   as int?;
    final iconB64     = group['icon']         as String?;
    final bannerB64   = group['banner']       as String?;

    return GestureDetector(
      onTap: () => context.push('/group-detail', extra: group),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: isMine ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner pequeño + ícono superpuesto ─────────────────
            Stack(clipBehavior: Clip.none, children: [
              // Banner
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
                ),
                child: bannerB64 != null
                    ? _b64Img(bannerB64, BoxFit.cover)
                    : Container(color: AppColors.onPrimary),
              ),
              // Ícono superpuesto en la esquina inferior izquierda
              Positioned(
                bottom: -24, left: 16,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    border: Border.all(color: isMine ? AppColors.primary : AppColors.text, width: 2),
                  ),
                  child: iconB64 != null
                      ? _b64Img(iconB64, BoxFit.cover)
                      : Container(
                          color: AppColors.primary,
                          child: Icon(Icons.group,
                              color: AppColors.onPrimary, size: 24)),
                ),
              ),
            ]),

            // ── Info ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(name.toUpperCase(),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w900, fontSize: 16,
                            color: AppColors.text, letterSpacing: -0.5, height: 1.1)),
                    SizedBox(height: 8),
                    // Descripción
                    if (description != null && description.isNotEmpty)
                      Text(description,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(fontSize: 12,
                              color: AppColors.textMuted, height: 1.3)),
                    const Spacer(),
                    // Miembros + equipo
                    Row(children: [
                      Icon(Icons.people_outline,
                          size: 14, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text(
                        '$members${maxMembers != null ? '/$maxMembers' : ''}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 14,
                            color: AppColors.text,
                            fontWeight: FontWeight.w900),
                      ),
                      if (team != null) ...[
                        SizedBox(width: 12),
                        Expanded(child: Text(team.toUpperCase(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(fontSize: 10,
                                color: AppColors.accentText, fontWeight: FontWeight.bold, letterSpacing: 1))),
                      ],
                    ]),
                    // Botón unirse
                    if (!isMine && onJoin != null) ...[
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onJoin,
                          child: Text('UNIRSE'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _b64Img(String data, BoxFit fit) {
    try {
      final bytes =
          base64Decode(data.contains(',') ? data.split(',').last : data);
      return Image.memory(bytes, fit: fit, width: double.infinity,
          height: double.infinity);
    } catch (_) {
      return Container(color: AppColors.onPrimary);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final FeedUser user;
  final double radius;
  const _Avatar({required this.user, required this.radius});

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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.color,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18, color: color),
    label: Text(label, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 14,
        fontWeight: FontWeight.w900)),
    style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.border, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'AHORA';
    if (diff.inMinutes < 60)  return 'HACE ${diff.inMinutes} MIN';
    if (diff.inHours   < 24)  return 'HACE ${diff.inHours} H';
    if (diff.inDays    < 7)   return 'HACE ${diff.inDays} D';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) { return ''; }
}

// ─────────────────────────────────────────────────────────────────────────────
// Equipos del Mundial 2026
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _wc2026Teams = [
  'Argentina','Brasil','Francia','Alemania','España','Portugal',
  'Inglaterra','Italia','Países Bajos','Bélgica','Croacia','Uruguay',
  'México','Estados Unidos','Canadá','Japón','Corea del Sur','Australia',
  'Marruecos','Senegal','Ghana','Nigeria','Camerún','Costa de Marfil',
  'Egipto','Túnez','Argelia','Arabia Saudita','Irán','Catar',
  'Polonia','Dinamarca','Suiza','Serbia','Ucrania','Austria',
  'Escocia','Noruega','Suecia','República Checa','Turquía',
  'Colombia','Ecuador','Chile','Perú','Venezuela','Costa Rica',
  'Panamá','Honduras','Jamaica','Irak',
];

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de creación de grupo
// ─────────────────────────────────────────────────────────────────────────────

class _CreateGroupSheet extends StatefulWidget {
  final int userId;
  final CommunityService svc;
  final void Function(String code) onCreated;
  const _CreateGroupSheet({
    required this.userId, required this.svc, required this.onCreated});
  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _maxCtrl     = TextEditingController();
  final _picker      = ImagePicker();
  String? _iconB64;
  String? _bannerB64;
  String? _selectedTeam;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery,
        imageQuality: 80, maxWidth: 400);
    if (xf == null) return;
    final b64 = 'data:image/jpeg;base64,${base64Encode(await xf.readAsBytes())}';
    setState(() => _iconB64 = b64);
  }

  Future<void> _pickBanner() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery,
        imageQuality: 80, maxWidth: 1200);
    if (xf == null) return;
    final b64 = 'data:image/jpeg;base64,${base64Encode(await xf.readAsBytes())}';
    setState(() => _bannerB64 = b64);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('EL NOMBRE ES OBLIGATORIO', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await widget.svc.createCommunity(
        _nameCtrl.text.trim(), widget.userId,
        maxMembers:   int.tryParse(_maxCtrl.text),
        favoriteTeam: _selectedTeam,
        description:  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        icon:         _iconB64,
        banner:       _bannerB64,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated(r['invitationCode'].toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(children: [
        // Handle
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(children: [
            Text('CREAR GRUPO',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.text, letterSpacing: -1)),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
              child: _saving
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.onPrimary, strokeWidth: 3))
                  : Text('CREAR',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ]),
        ),
        Divider(height: 2, color: AppColors.border),

        // Scrollable form
        Flexible(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 32 + bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Banner ───────────────────────────────────────────────
            _label('BANNER DEL GRUPO'),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _pickBanner,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: _bannerB64 != null
                    ? Stack(fit: StackFit.expand, children: [
                        Image.memory(
                          base64Decode(_bannerB64!.split(',').last),
                          fit: BoxFit.cover),
                        Positioned(bottom: 8, right: 8,
                          child: _editChip('CAMBIAR')),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('AGREGAR BANNER',
                              style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ]),
              ),
            ),
            SizedBox(height: 32),

            // ── Ícono ────────────────────────────────────────────────
            _label('ÍCONO DEL GRUPO'),
            SizedBox(height: 12),
            Row(children: [
              GestureDetector(
                onTap: _pickIcon,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: _iconB64 != null
                      ? Image.memory(
                          base64Decode(_iconB64!.split(',').last),
                          fit: BoxFit.cover)
                      : Icon(Icons.group, size: 32, color: AppColors.textMuted),
                ),
              ),
              SizedBox(width: 24),
              OutlinedButton.icon(
                onPressed: _pickIcon,
                icon: Icon(Icons.upload_rounded, size: 20),
                label: Text(_iconB64 == null ? 'SUBIR ÍCONO' : 'CAMBIAR ÍCONO'),
              ),
            ]),
            SizedBox(height: 32),

            // ── Nombre ───────────────────────────────────────────────
            _label('NOMBRE DEL GRUPO *'),
            SizedBox(height: 12),
            _input(_nameCtrl, 'EJ: LOS CAMPEONES DEL MUNDO'),
            SizedBox(height: 24),

            // ── Descripción ──────────────────────────────────────────
            _label('DESCRIPCIÓN'),
            SizedBox(height: 12),
            _input(_descCtrl, 'CUÉNTALES A LOS DEMÁS DE QUÉ VA ESTE GRUPO...',
                maxLines: 3),
            SizedBox(height: 24),

            // ── Equipo favorito ──────────────────────────────────────
            _label('EQUIPO FAVORITO'),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTeam,
                  isExpanded: true,
                  dropdownColor: AppColors.background,
                  hint: Text('SELECCIONA UN EQUIPO',
                      style: GoogleFonts.dmSans(color: AppColors.border, fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.expand_more, color: AppColors.textMuted),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('SIN EQUIPO FAVORITO',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                    ),
                    ..._wc2026Teams.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: AppColors.text)),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedTeam = v),
                ),
              ),
            ),
            SizedBox(height: 24),

            // ── Máx. miembros ────────────────────────────────────────
            _label('MÁXIMO DE MIEMBROS (OPCIONAL)'),
            SizedBox(height: 12),
            _input(_maxCtrl, 'SIN LÍMITE',
                type: TextInputType.number),
          ]),
        )),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold,
          color: AppColors.accentText, letterSpacing: 1));

  Widget _input(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType type = TextInputType.text}) =>
    TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: type,
      style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
      cursorColor: AppColors.accentText,
      decoration: InputDecoration(
        hintText: hint,
      ),
    );

  Widget _editChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.onPrimary, border: Border.all(color: AppColors.text, width: 2)),
    child: Text(label,
        style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontSize: 12,
            fontWeight: FontWeight.w900, letterSpacing: 1)),
  );
}
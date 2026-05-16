import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/community_service.dart';
import '../services/feed_service.dart';
import '../services/auth/auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class ComunidadesScreen extends StatelessWidget {
  const ComunidadesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF00341C),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Comunidades',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [Tab(text: 'Feed'), Tab(text: 'Mis grupos')],
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
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewPost,
        backgroundColor: const Color(0xFF00341C),
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00341C)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF00341C),
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
      Icon(Icons.dynamic_feed_outlined, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('Sé el primero en publicar',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      const SizedBox(height: 8),
      Text('Toca + para crear una publicación',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.black87),
            title: const Text('Editar publicación',
                style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () { Navigator.pop(sheetCtx); _openEdit(); },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade600),
            title: Text('Eliminar publicación',
                style: TextStyle(color: Colors.red.shade600,
                    fontWeight: FontWeight.w500)),
            onTap: () { Navigator.pop(sheetCtx); _confirmDelete(); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _openEdit() {
    final ctrl = TextEditingController(text: _post.content);
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Editar publicación',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        content: TextField(
          controller: ctrl, maxLines: 6, minLines: 2, autofocus: true,
          decoration: InputDecoration(
            hintText: '¿Qué está pasando en el Mundial?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00341C),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
            onPressed: () async {
              final newContent = ctrl.text.trim();
              Navigator.pop(dlgCtx);
              try {
                final updated = await _svc.editPost(_post.id, newContent);
                if (mounted) setState(() => _post.content = updated.content);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Guardar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Eliminar publicación',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              try {
                await _svc.deletePost(_post.id);
                if (mounted) widget.onDelete();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Eliminar'),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
          child: Row(children: [
            _Avatar(user: _post.user, radius: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_post.user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 14, color: Colors.black87)),
                Text(time, style: TextStyle(fontSize: 11,
                    color: Colors.grey.shade500)),
              ])),
            if (isOwn)
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 20),
                onPressed: _showOptions,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ]),
        ),

        // Content
        if (_post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(_post.content,
                style: const TextStyle(fontSize: 14, color: Colors.black87,
                    height: 1.45)),
          ),

        // Images
        if (_post.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ImageGrid(images: _post.images),
        ],

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(children: [
            _ActionButton(
              icon: _post.likedByMe ? Icons.favorite : Icons.favorite_border,
              color: _post.likedByMe ? Colors.red.shade500 : Colors.grey.shade600,
              label: '${_post.likeCount}',
              onTap: _toggleLike,
            ),
            const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.chat_bubble_outline,
              color: Colors.grey.shade600,
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
      return _FullImage(data: images[0], maxWidth: screenW);
    }
    // Multiple images: horizontal scroll, each shown complete
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: images.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(right: e.key < images.length - 1 ? 8 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
    if (isBase64) {
      try {
        final bytes = base64Decode(data.contains(',') ? data.split(',').last : data);
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 480),
          child: Image.memory(bytes,
            width: maxWidth, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _placeholder()),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 480),
      child: Image.network(data,
        width: maxWidth, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder()),
    );
  }

  Widget _placeholder() => Container(
    width: maxWidth, height: 120,
    color: Colors.grey.shade100,
    child: Icon(Icons.broken_image_outlined,
        color: Colors.grey.shade400, size: 32));
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // Handle
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        // Title
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Text('Comentarios',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            Text('${widget.post.commentCount}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ])),
        Divider(height: 1, color: Colors.grey.shade200),

        // List
        Flexible(child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00341C)))
          : _comments.isEmpty
            ? Padding(padding: const EdgeInsets.all(32),
                child: Text('Sin comentarios aún. ¡Sé el primero!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _comments.length,
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
            color: const Color(0xFF00341C).withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.reply, size: 16, color: const Color(0xFF00341C)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Respondiendo a ${_replyingTo!.user.displayName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF00341C),
                    fontWeight: FontWeight.w500))),
              GestureDetector(
                onTap: () => setState(() => _replyingTo = null),
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade600)),
            ]),
          ),

        // Input
        Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom),
          child: Row(children: [
            _Avatar(user: FeedUser(
              id: AuthService().currentUserId ?? 0,
              firstName: AuthService().currentUser?['firstName'] ?? '',
              lastName:  AuthService().currentUser?['lastName'] ?? '',
            ), radius: 16),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: _replyingTo != null ? 'Responder...' : 'Añadir comentario...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF00341C))),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Color(0xFF00341C), shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
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
          padding: const EdgeInsets.only(left: 56),
          child: GestureDetector(
            onTap: () => setState(() => _showReplies = !_showReplies),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _showReplies
                    ? 'Ocultar respuestas'
                    : 'Ver ${widget.comment.replies.length} respuesta(s)',
                style: const TextStyle(fontSize: 12,
                    color: Color(0xFF00341C), fontWeight: FontWeight.w600),
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
      padding: EdgeInsets.fromLTRB(16 + indent, 8, 16, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(user: c.user, radius: 14),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(c.user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 13, color: Colors.black87)),
              const SizedBox(width: 6),
              Text(_formatTime(c.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
            const SizedBox(height: 2),
            Text(c.content,
                style: const TextStyle(fontSize: 13, color: Colors.black87,
                    height: 1.4)),
            const SizedBox(height: 4),
            Row(children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(children: [
                  Icon(
                    c.likedByMe ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: c.likedByMe ? Colors.red.shade500 : Colors.grey.shade500,
                  ),
                  if (c.likeCount > 0) ...[
                    const SizedBox(width: 3),
                    Text('${c.likeCount}',
                        style: TextStyle(fontSize: 11,
                            color: Colors.grey.shade500)),
                  ],
                ]),
              ),
              const SizedBox(width: 16),
              if (indent == 0)
                GestureDetector(
                  onTap: () => widget.onReply(c),
                  child: Text('Responder',
                      style: TextStyle(fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
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
  List<String> _images = [];
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle + header
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(children: [
            const Text('Nueva publicación',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            ElevatedButton(
              onPressed: _posting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00341C),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: _posting
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white,
                          strokeWidth: 2))
                  : const Text('Publicar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade200),

        // Text input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Avatar(user: FeedUser(
              id: AuthService().currentUserId ?? 0,
              firstName: user['firstName'] ?? '',
              lastName: user['lastName'] ?? '',
              avatar: user['profilePicture'],
            ), radius: 18),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: _ctrl,
              maxLines: 5,
              minLines: 2,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '¿Qué está pasando en el Mundial?',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            )),
          ]),
        ),

        // Image previews
        if (_images.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _images.length + (_images.length < 4 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == _images.length) return _addImageBtn();
                return Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(_images[i].contains(',')
                          ? _images[i].split(',').last : _images[i]),
                      width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 12)),
                    )),
                ]);
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [_addImageBtn()]),
          ),

        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _addImageBtn() => GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined,
            color: Colors.grey.shade500, size: 28),
        const SizedBox(height: 4),
        Text('Foto', style: TextStyle(fontSize: 11,
            color: Colors.grey.shade500)),
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
      if (mounted) setState(() {
        _mine      = results[0];
        _suggested = results[1];
        _loading   = false;
      });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Unirse con código',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: 'Código', isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00341C),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          onPressed: () async {
            try {
              await _svc.joinCommunity(int.parse(ctrl.text), _userId);
              if (!mounted) return;
              Navigator.pop(dlgCtx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('¡Te uniste!')));
              _load();
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: const Text('Unirse', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ));
  }

  void _showCode(String code) {
    showDialog(context: context, builder: (dlgCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Grupo creado', style: TextStyle(fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Comparte este código con tus amigos:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF00341C).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8)),
          child: Text(code, style: const TextStyle(fontSize: 36,
              fontWeight: FontWeight.bold, letterSpacing: 4,
              color: Color(0xFF00341C))),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dlgCtx),
          child: const Text('Cerrar', style: TextStyle(color: Color(0xFF00341C))))],
    ));
  }

  Future<void> _joinSuggested(Map<String, dynamic> group) async {
    final code = int.tryParse(group['invitationCode'].toString());
    if (code == null) return;
    try {
      await _svc.joinCommunity(code, _userId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('¡Te uniste a ${group['name']}!')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF00341C),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00341C)))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Acciones
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: _showCreate,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Crear grupo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00341C),
                      foregroundColor: Colors.white, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _showJoin,
                    icon: const Icon(Icons.group_add, size: 18),
                    label: const Text('Unirme'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  )),
                ]),
                const SizedBox(height: 32),

                // Mis grupos
                _sectionHeader('Mis grupos', '${_mine.length}'),
                const SizedBox(height: 12),
                if (_mine.isEmpty)
                  _emptyState(
                    icon: Icons.group_outlined,
                    message: 'Aún no perteneces a ningún grupo.',
                    sub: 'Crea uno o únete con un código.',
                  )
                else
                  _groupGrid(_mine, isMine: true),

                const SizedBox(height: 32),

                // Grupos sugeridos
                _sectionHeader('Grupos sugeridos', null),
                const SizedBox(height: 12),
                if (_suggested.isEmpty)
                  _emptyState(
                    icon: Icons.explore_outlined,
                    message: 'No hay grupos sugeridos disponibles.',
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
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 195,
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
    Text(title, style: const TextStyle(fontSize: 16,
        fontWeight: FontWeight.w700, color: Colors.black87)),
    if (count != null) ...[
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF00341C).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
        child: Text(count, style: const TextStyle(fontSize: 12,
            color: Color(0xFF00341C), fontWeight: FontWeight.w600)),
      ),
    ],
  ]);

  Widget _emptyState({required IconData icon, required String message, String? sub}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        Icon(icon, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
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
    final name        = group['name']          as String? ?? 'Sin nombre';
    final description = group['description']  as String?;
    final team        = group['favoriteTeam'] as String?;
    final members     = group['memberCount']  as int?    ?? 0;
    final maxMembers  = group['maxMembers']   as int?;
    final iconB64     = group['icon']         as String?;
    final bannerB64   = group['banner']       as String?;

    return GestureDetector(
      onTap: () => context.push('/group-detail', extra: group),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMine
                ? const Color(0xFF00341C).withValues(alpha: 0.4)
                : Colors.grey.shade300,
            width: isMine ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner pequeño + ícono superpuesto ─────────────────
            Stack(clipBehavior: Clip.none, children: [
              // Banner
              SizedBox(
                height: 72,
                width: double.infinity,
                child: bannerB64 != null
                    ? _b64Img(bannerB64, BoxFit.cover)
                    : Container(
                        color: const Color(0xFF00341C).withValues(alpha: 0.08)),
              ),
              // Ícono superpuesto en la esquina inferior izquierda
              Positioned(
                bottom: -18, left: 10,
                child: Container(
                  width: 36, height: 36,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4)],
                  ),
                  child: iconB64 != null
                      ? _b64Img(iconB64, BoxFit.cover)
                      : Container(
                          color: const Color(0xFF00341C).withValues(alpha: 0.1),
                          child: const Icon(Icons.group,
                              color: Color(0xFF00341C), size: 18)),
                ),
              ),
            ]),

            // ── Info ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 22, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(name,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12,
                            color: Colors.black87, height: 1.3)),
                    const SizedBox(height: 3),
                    // Descripción
                    if (description != null && description.isNotEmpty)
                      Text(description,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10,
                              color: Colors.grey.shade500, height: 1.3)),
                    const Spacer(),
                    // Miembros + equipo
                    Row(children: [
                      Icon(Icons.people_outline,
                          size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        '$members${maxMembers != null ? '/$maxMembers' : ''}',
                        style: TextStyle(fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600),
                      ),
                      if (team != null) ...[
                        const SizedBox(width: 6),
                        Expanded(child: Text(team,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9,
                                color: Colors.grey.shade400))),
                      ],
                    ]),
                    // Botón unirse
                    if (!isMine && onJoin != null) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00341C),
                            foregroundColor: Colors.white, elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6))),
                          child: const Text('Unirse',
                              style: TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600)),
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
      return Container(color: Colors.grey.shade100);
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
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF00341C),
      backgroundImage: img,
      child: img == null
          ? Text(user.initials,
              style: TextStyle(color: Colors.white,
                  fontSize: radius * 0.7, fontWeight: FontWeight.w600))
          : null,
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
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18, color: color),
    label: Text(label, style: TextStyle(color: color, fontSize: 13,
        fontWeight: FontWeight.w500)),
    style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatTime(String iso) {
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
          const SnackBar(content: Text('El nombre es obligatorio')));
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
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // Handle
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
          child: Row(children: [
            const Text('Crear grupo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00341C),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Crear',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade200),

        // Scrollable form
        Flexible(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Banner ───────────────────────────────────────────────
            _label('Banner del grupo'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickBanner,
              child: Container(
                height: 130,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF00341C).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _bannerB64 != null
                    ? Stack(fit: StackFit.expand, children: [
                        Image.memory(
                          base64Decode(_bannerB64!.split(',').last),
                          fit: BoxFit.cover),
                        Positioned(bottom: 8, right: 8,
                          child: _editChip('Cambiar')),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text('Agregar banner',
                              style: TextStyle(color: Colors.grey.shade500,
                                  fontSize: 13)),
                        ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── Ícono ────────────────────────────────────────────────
            _label('Ícono del grupo'),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: _pickIcon,
                child: Container(
                  width: 80, height: 80,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00341C).withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: _iconB64 != null
                      ? Image.memory(
                          base64Decode(_iconB64!.split(',').last),
                          fit: BoxFit.cover)
                      : Icon(Icons.group, size: 32, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 14),
              TextButton.icon(
                onPressed: _pickIcon,
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(_iconB64 == null ? 'Subir ícono' : 'Cambiar ícono'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00341C)),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Nombre ───────────────────────────────────────────────
            _label('Nombre del grupo *'),
            const SizedBox(height: 8),
            _input(_nameCtrl, 'Ej: Los Campeones del Mundo'),
            const SizedBox(height: 16),

            // ── Descripción ──────────────────────────────────────────
            _label('Descripción'),
            const SizedBox(height: 8),
            _input(_descCtrl, 'Cuéntales a los demás de qué va este grupo...',
                maxLines: 3),
            const SizedBox(height: 16),

            // ── Equipo favorito ──────────────────────────────────────
            _label('Equipo favorito'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTeam,
                  isExpanded: true,
                  hint: Text('Selecciona un equipo',
                      style: TextStyle(color: Colors.grey.shade400,
                          fontSize: 14)),
                  icon: Icon(Icons.expand_more,
                      color: Colors.grey.shade500),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Sin equipo favorito',
                          style: TextStyle(color: Colors.grey.shade500,
                              fontSize: 14)),
                    ),
                    ..._wc2026Teams.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: const TextStyle(fontSize: 14)),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedTeam = v),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Máx. miembros ────────────────────────────────────────
            _label('Máximo de miembros (opcional)'),
            const SizedBox(height: 8),
            _input(_maxCtrl, 'Sin límite',
                type: TextInputType.number),
          ]),
        )),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: Colors.black87));

  Widget _input(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType type = TextInputType.text}) =>
    TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00341C))),
      ),
    );

  Widget _editChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: const TextStyle(color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w500)),
  );
}

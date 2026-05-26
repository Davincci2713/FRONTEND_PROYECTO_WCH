import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth.dart';
import '../utils/platform_reload.dart';
class FeedPost {
  final int id;
  String content;
  final String createdAt;
  final FeedUser user;
  final List<String> images;
  int likeCount;
  bool likedByMe;
  int commentCount;

  FeedPost({
    required this.id, required this.content, required this.createdAt,
    required this.user, required this.images,
    required this.likeCount, required this.likedByMe, required this.commentCount,
  });

  factory FeedPost.fromJson(Map<String, dynamic> j) => FeedPost(
    id:           j['id'] as int,
    content:      j['content'] as String? ?? '',
    createdAt:    j['createdAt'] as String? ?? '',
    user:         FeedUser.fromJson(j['user'] as Map<String, dynamic>),
    images:       List<String>.from(j['images'] as List? ?? []),
    likeCount:    j['likeCount'] as int? ?? 0,
    likedByMe:    j['likedByMe'] as bool? ?? false,
    commentCount: j['commentCount'] as int? ?? 0,
  );
}

class FeedUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatar;

  FeedUser({required this.id, required this.firstName,
            required this.lastName, this.avatar});

  factory FeedUser.fromJson(Map<String, dynamic> j) => FeedUser(
    id:        j['id'] as int,
    firstName: j['firstName'] as String? ?? '',
    lastName:  j['lastName'] as String? ?? '',
    avatar:    j['avatar'] as String?,
  );

  String get displayName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty  ? lastName[0]  : '';
    return (f + l).toUpperCase();
  }
}

class FeedComment {
  final int id;
  final String content;
  final String createdAt;
  final FeedUser user;
  int likeCount;
  bool likedByMe;
  final int? parentId;
  final List<FeedComment> replies;

  FeedComment({
    required this.id, required this.content, required this.createdAt,
    required this.user, required this.likeCount, required this.likedByMe,
    this.parentId, required this.replies,
  });

  factory FeedComment.fromJson(Map<String, dynamic> j) => FeedComment(
    id:        j['id'] as int,
    content:   j['content'] as String? ?? '',
    createdAt: j['createdAt'] as String? ?? '',
    user:      FeedUser.fromJson(j['user'] as Map<String, dynamic>),
    likeCount: j['likeCount'] as int? ?? 0,
    likedByMe: j['likedByMe'] as bool? ?? false,
    parentId:  j['parentId'] as int?,
    replies:   (j['replies'] as List? ?? [])
                  .map((e) => FeedComment.fromJson(e as Map<String, dynamic>))
                  .toList(),
  );
}

class FeedService {
  String get _base => AuthService().baseUrl;
  Map<String, String> get _h => AuthService().getAuthHeaders();

  Future<List<FeedPost>> getFeed({int page = 1, int? groupId}) async {
    final uid = AuthService().currentUserId ?? 0;
    final extra = groupId != null ? '&group_id=$groupId' : '';
    final r = await http.get(
      Uri.parse('$_base/feed?viewer_id=$uid&page=$page$extra'), headers: _h);
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as List)
          .map((e) => FeedPost.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error cargando el feed');
  }

  Future<FeedPost> createPost(String content, List<String> images,
      {int? groupId}) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw Exception('No autenticado');
    final body = {'userId': uid, 'content': content, 'images': images};
    if (groupId != null) body['groupId'] = groupId;
    final r = await http.post(Uri.parse('$_base/feed'),
        headers: _h, body: jsonEncode(body));
    if (r.statusCode == 201) {
      reloadPlatform(() {});
      return FeedPost.fromJson(jsonDecode(r.body));
    }
    throw Exception(jsonDecode(r.body)['error'] ?? 'Error al publicar');
  }

  Future<FeedPost> editPost(int postId, String content) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw Exception('No autenticado');
    final r = await http.patch(Uri.parse('$_base/feed/$postId'),
      headers: _h, body: jsonEncode({'userId': uid, 'content': content}));
    if (r.statusCode == 200) return FeedPost.fromJson(jsonDecode(r.body));
    throw Exception(jsonDecode(r.body)['error'] ?? 'Error al editar');
  }

  Future<void> deletePost(int postId) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw Exception('No autenticado');
    final r = await http.delete(
      Uri.parse('$_base/feed/$postId?userId=$uid'),
      headers: _h,
      body: jsonEncode({'userId': uid}),
    );
    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception(jsonDecode(r.body)['error'] ?? 'Error al eliminar la publicación');
    }
    reloadPlatform(() {});
  }

  Future<Map<String, dynamic>> toggleLike(int postId) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw Exception('No autenticado');
    final r = await http.post(Uri.parse('$_base/feed/$postId/like'),
      headers: _h, body: jsonEncode({'userId': uid}));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<FeedComment>> getComments(int postId) async {
    final uid = AuthService().currentUserId ?? 0;
    final r = await http.get(
      Uri.parse('$_base/feed/$postId/comments?viewer_id=$uid'), headers: _h);
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as List)
          .map((e) => FeedComment.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error cargando comentarios');
  }

  Future<FeedComment> addComment(int postId, String content, {int? parentId}) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw Exception('No autenticado');
    final body = {'userId': uid, 'content': content};
    if (parentId != null) body['parentId'] = parentId;
    final r = await http.post(Uri.parse('$_base/feed/$postId/comments'),
      headers: _h, body: jsonEncode(body));
    if (r.statusCode == 201) return FeedComment.fromJson(jsonDecode(r.body));
    throw Exception(jsonDecode(r.body)['error'] ?? 'Error al comentar');
  }

  Future<void> deleteComment(int commentId) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw Exception('No autenticado');
    final r = await http.delete(
      Uri.parse('$_base/feed/comments/$commentId?userId=$uid'),
      headers: _h,
      body: jsonEncode({'userId': uid}),
    );
    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception(jsonDecode(r.body)['error'] ?? 'Error al eliminar el comentario');
    }
  }

  Future<Map<String, dynamic>> toggleCommentLike(int commentId) async {
    final uid = AuthService().currentUserId;
    if (uid == null) throw Exception('No autenticado');
    final r = await http.post(Uri.parse('$_base/feed/comments/$commentId/like'),
      headers: _h, body: jsonEncode({'userId': uid}));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}

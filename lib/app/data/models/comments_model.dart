import 'package:get/get.dart';
import 'profile_model.dart';

class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final String userId;
  final String videoId;
  final String? parentCommentId;
  final Profile author;

  late final RxInt likeCount;
  late final RxBool isLiked;
  final RxList<Comment> replies = <Comment>[].obs;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.videoId,
    this.parentCommentId,
    required this.author,
    required int initialLikeCount,
    required bool initialIsLiked,
  }) {
    likeCount = initialLikeCount.obs;
    isLiked = initialIsLiked.obs;
  }

  String get username => author.username.value;
  String get avatarUrl => author.avatarUrl.value;

  factory Comment.fromSupabase(Map<String, dynamic> json, {required String currentUserId}) {
    final likesData = json['comment_likes'] as List? ?? [];
    var profileJson = json['profiles'] as Map<String, dynamic>?;

    // SỬA LỖI 2: Xử lý profile bị thiếu một cách an toàn thay vì throw exception
    if (profileJson == null) {
      print('Warning: Comment with id ${json['id']} is missing profile data. Using default author.');
      // Tạo một profile mặc định khi dữ liệu bị thiếu
      profileJson = {};
    }

    return Comment(
      id: json['id'].toString(),
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
      videoId: json['video_id'],
      parentCommentId: json['parent_comment_id']?.toString(),
      // SỬA LỖI 1: Truyền đúng `currentUserId` vào cho Profile.fromJson
      author: Profile.fromJson(profileJson, currentUserId: currentUserId),
      initialLikeCount: likesData.length,
      initialIsLiked: currentUserId.isNotEmpty && likesData.any((like) => like['user_id'] == currentUserId),
    );
  }
}
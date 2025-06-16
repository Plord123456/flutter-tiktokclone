import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart'; // Đảm bảo import đúng đường dẫn

class Comment {
  final String id;
  final String content;
  final String username;
  final String avatarUrl;
  final DateTime createdAt;
  final String userId;
  final String videoId;
  // ✅ SỬA LỖI: Thêm trường parentCommentId còn thiếu.
  // Nó có thể là null nên ta dùng kiểu int?
  final int? parentCommentId;
  final Profile? profile;

  // Các trường trạng thái cho UI
  final RxBool isLiked;
  final RxList<Comment> replies;

  Comment({
    required this.id,
    required this.content,
    required this.username,
    required this.avatarUrl,
    required this.createdAt,
    required this.userId,
    required this.videoId,
    this.parentCommentId, // Thêm vào constructor
    this.profile,
    bool isLiked = false,
    List<Comment>? replies,
  })  : this.isLiked = isLiked.obs,
        this.replies = (replies ?? <Comment>[]).obs;

  factory Comment.fromJson(Map<String, dynamic> json) {
    final userProfile = json['profiles'];
    return Comment(
      id: json['id']?.toString() ?? '',
      content: json['content'] as String? ?? 'Nội dung không khả dụng',
      username: userProfile != null ? userProfile['username'] ?? 'Vô danh' : 'Vô danh',
      avatarUrl: userProfile != null ? userProfile['avatar_url'] ?? '' : '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      userId: json['user_id'] as String? ?? '',
      videoId: json['video_id'] as String? ?? '',
      // ✅ SỬA LỖI: Parse trường parent_comment_id từ JSON.
      parentCommentId: json['parent_comment_id'],
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'])
          : null,
    );
  }
}

extension CommentCopyWith on Comment {
  Comment copyWith({
    String? id,
    String? content,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    String? userId,
    String? videoId,
    int? parentCommentId, // Thêm vào copyWith
    Profile? profile,
    bool? isLiked,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      videoId: videoId ?? this.videoId,
      // ✅ SỬA LỖI: Thêm vào copyWith
      parentCommentId: parentCommentId ?? this.parentCommentId,
      profile: profile ?? this.profile,
      isLiked: isLiked ?? this.isLiked.value,
      replies: replies ?? this.replies,
    );
  }
}

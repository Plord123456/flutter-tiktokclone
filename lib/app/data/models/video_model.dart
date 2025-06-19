import 'package:get/get.dart';
import 'profile_model.dart'; // Import Profile model

// Helper function này đã rất tốt, giữ nguyên
int _parseCountFromList(dynamic jsonField) {
  if (jsonField is List && jsonField.isNotEmpty) {
    return (jsonField.first as Map<String, dynamic>?)?['count'] as int? ?? 0;
  }
  return 0;
}


class Video {
  final String id, videoUrl, title, thumbnailUrl;
  final DateTime createdAt;
  final Profile author;
  late final RxInt likeCount, commentCount;
  late final RxBool isLikedByCurrentUser, isFollowedByCurrentUser;

  Video({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.author,
    required int initialLikeCount,
    required int initialCommentCount,
    required bool initialIsLiked,
    required bool initialIsFollowed,
  }) {
    likeCount = initialLikeCount.obs;
    commentCount = initialCommentCount.obs;
    isLikedByCurrentUser = initialIsLiked.obs;
    isFollowedByCurrentUser = initialIsFollowed.obs;
  }

  // ✅ PHIÊN BẢN FACTORY HOÀN CHỈNH VÀ ĐÚNG LOGIC
  factory Video.fromSupabase(Map<String, dynamic> json, {
    required String currentUserId,
    required bool isFollowed,
    bool isLiked = false, // Tham số này sẽ được HomeController truyền vào
    Profile? author,
  }) {
    final createdAtStr = json['created_at'] as String?;
    final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) ?? DateTime.now() : DateTime.now();

    // Logic xử lý author đã đúng
    final finalAuthor = author ?? Profile.fromJson(
      json['profiles'] as Map<String, dynamic>? ?? {},
      currentUserId: currentUserId,
    );

    // ✅ SỬA LẠI HOÀN TOÀN LOGIC LẤY LIKE VÀ COMMENT
    // Lấy tổng số lượt thích từ trường 'likes_count' mà HomeController trả về
    final initialLikeCount = _parseCountFromList(json['likes_count']);

    // Lấy tổng số bình luận từ trường 'comments_count'
    final initialCommentCount = _parseCountFromList(json['comments_count']);

    return Video(
      id: json['id'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      createdAt: createdAt,
      author: finalAuthor,
      initialLikeCount: initialLikeCount,
      initialCommentCount: initialCommentCount,
      // Sử dụng trực tiếp giá trị isLiked được truyền từ HomeController
      initialIsLiked: isLiked,
      initialIsFollowed: isFollowed,
    );
  }
}
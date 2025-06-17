import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart'; // Đảm bảo đường dẫn này đúng

class Video {
  final String id;
  final String videoUrl;
  final String title;
  final String thumbnailUrl;
  final DateTime createdAt;

  final Profile author;

  late final RxInt likeCount;
  late final RxInt commentCount;
  late final RxBool isLikedByCurrentUser;
  late final RxBool isFollowedByCurrentUser;

  /// ✅ FIX: Constructor nhận các giá trị 'initial' kiểu nguyên thủy.
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
    // ✅ FIX: Bên trong constructor, chuyển đổi giá trị nguyên thủy thành Rx.
    likeCount = initialLikeCount.obs;
    commentCount = initialCommentCount.obs;
    isLikedByCurrentUser = initialIsLiked.obs;
    isFollowedByCurrentUser = initialIsFollowed.obs;
  }

  /// ✅ FIX: Factory `fromSupabase` chuẩn bị các giá trị bool/int
  /// và truyền chúng vào các tham số `initial...` của constructor.
  factory Video.fromSupabase(Map<String, dynamic> json, {
    required String currentUserId,
    required bool isFollowed,
  }) {
    final likesData = json['likes'] as List? ?? [];
    final commentsCountData = json['comments_count'] as List? ?? [];
    final profileData = json['profiles'];

    if (profileData == null) {
      // Ném lỗi hoặc trả về một giá trị mặc định nếu không có profile
      // Điều này giúp tránh lỗi ở các bước sau.
      throw Exception('Video with id ${json['id']} is missing profile data.');
    }

    return Video(
      id: json['id'],
      videoUrl: json['video_url'],
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),

      // Tạo đối tượng author từ dữ liệu lồng nhau
      author: Profile.fromJson(profileData),

      // Truyền các giá trị nguyên thủy đã được tính toán
      initialLikeCount: likesData.length,
      initialCommentCount: commentsCountData.isNotEmpty ? commentsCountData.first['count'] : 0,
      initialIsLiked: currentUserId.isNotEmpty && likesData.any((like) => like['user_id'] == currentUserId),
      initialIsFollowed: isFollowed,
    );
  }
}
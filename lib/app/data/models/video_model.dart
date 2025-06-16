
import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/tag_model.dart';

class Video {
  final String id;
  final String videoUrl;
  final String title;
  final String username;
  final String profilePhoto;
  final String postedById;
  final String thumbnailUrl;
  final DateTime createdAt;
  // Rx-Values for reactive UI updates
  late final RxInt likeCount;
  late final RxInt commentCount;
  late final RxBool isLikedByCurrentUser;

  // New field for follow status
  final bool isFollowed;

  // Danh sách tags
  final List<Tag> tags;

  Video({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.username,
    required this.createdAt,
    required this.profilePhoto,
    required this.postedById,
    required this.thumbnailUrl,
    required int initialLikeCount,
    required int initialCommentCount,
    required bool initialIsLiked,
    required bool initialIsFollowed, // Add required
    this.tags = const [],
  })  : isFollowed = initialIsFollowed, // Assign to field
        likeCount = initialLikeCount.obs,
        commentCount = initialCommentCount.obs,
        isLikedByCurrentUser = initialIsLiked.obs;

  factory Video.fromJson(Map<String, dynamic> json) {
    try {
      final userProfile = json['profiles'] ?? json['profile'] ?? {};
      final tagsData = json['tags'] as List? ?? [];

      return Video(
        id: json['id'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
        videoUrl: json['video_url'] as String? ?? '',
        title: json['title'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String? ?? '',
        postedById: json['user_id'] as String? ?? '',
        username: userProfile['username'] as String? ?? 'Unknown User',
        profilePhoto: userProfile['avatar_url'] as String? ?? '',
        initialLikeCount: (json['like_count'] as num?)?.toInt() ?? 0,
        initialCommentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
        initialIsLiked: json['is_liked_by_me'] as bool? ?? false,
        initialIsFollowed: json['is_followed'] as bool? ?? false,
        tags: tagsData.map((tagJson) => Tag.fromJson(tagJson)).toList(),
      );
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể phân tích dữ liệu video: ${e.toString()}');
      return Video(
        id: '',
        videoUrl: '',
        title: 'Lỗi tải video',
        username: 'Unknown User',
        profilePhoto: '',
        postedById: '',
        thumbnailUrl: '',
        initialLikeCount: 0,
        initialCommentCount: 0,
        initialIsLiked: false,
        initialIsFollowed: false,
        tags: [],
        createdAt: DateTime.now(),
      );
    }
  }
}
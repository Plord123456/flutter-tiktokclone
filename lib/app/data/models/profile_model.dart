import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart'; // Đảm bảo đã import Video model

// Helper function để parse số đếm một cách an toàn
int _parseCount(dynamic jsonField) {
  // Xử lý trường hợp Supabase trả về count dưới dạng list: [{'count': 10}]
  if (jsonField is List && jsonField.isNotEmpty) {
    return (jsonField.first as Map<String, dynamic>?)?['count'] as int? ?? 0;
  }
  // Xử lý trường hợp count là một số hoặc null
  return (jsonField as num?)?.toInt() ?? 0;
}

class Profile {
  final String id;
  final DateTime createdAt;
  late final RxString username, fullName, avatarUrl;
  late final RxInt postCount, followerCount, followingCount;
  late final RxList<Video> videos;

  Profile({
    required this.id,
    required this.createdAt,
    required String initialUsername,
    required String initialFullName,
    required String initialAvatarUrl,
    required int initialPostCount,
    required int initialFollowerCount,
    required int initialFollowingCount,
    List<Video>? initialVideos,
  }) {
    username = initialUsername.obs;
    fullName = initialFullName.obs;
    avatarUrl = initialAvatarUrl.obs;
    postCount = initialPostCount.obs;
    followerCount = initialFollowerCount.obs;
    followingCount = initialFollowingCount.obs;
    videos = (initialVideos ?? <Video>[]).obs;
  }

  // SỬA LẠI SIGNATURE: Bỏ 'currentUserIdParam' không cần thiết.
  // Giờ đây, người gọi chỉ cần truyền 'currentUserId' một lần duy nhất.
  factory Profile.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    return Profile(
      id: json['id'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      initialUsername: json['username'] ?? 'vô danh',
      initialFullName: json['full_name'] ?? '',
      initialAvatarUrl: json['avatar_url'] ?? '',
      // Sử dụng helper function để parse các trường count
      initialPostCount: _parseCount(json['post_count']),
      initialFollowerCount: _parseCount(json['follower_count']),
      initialFollowingCount: _parseCount(json['following_count']),
      // Parse danh sách video (nếu có)
      initialVideos: (json['videos'] as List<dynamic>?)
          ?.map((v) => Video.fromSupabase(
          v as Map<String, dynamic>,
          currentUserId: currentUserId, // Sử dụng trực tiếp tham số đã được yêu cầu
          isFollowed: false // isFollowed cần logic riêng nếu có
      ))
          .toList(), // Fallback về null nếu không có 'videos', constructor sẽ xử lý
    );
  }

  // Phương thức cập nhật profile, đã rất tốt
  void updateProfile({
    String? newUsername,
    String? newFullName,
    String? newAvatarUrl,
    int? newPostCount,
    int? newFollowerCount,
    int? newFollowingCount,
    List<Video>? newVideos,
  }) {
    if (newUsername != null) username.value = newUsername;
    if (newFullName != null) fullName.value = newFullName;
    if (newAvatarUrl != null) avatarUrl.value = newAvatarUrl;
    if (newPostCount != null) postCount.value = newPostCount;
    if (newFollowerCount != null) followerCount.value = newFollowerCount;
    if (newFollowingCount != null) followingCount.value = newFollowingCount;
    if (newVideos != null) videos.assignAll(newVideos);
  }
}
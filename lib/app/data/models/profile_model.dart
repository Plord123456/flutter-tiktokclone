import 'package:get/get.dart';

// Helper function
int _parseCount(dynamic jsonField) {
  if (jsonField is List && jsonField.isNotEmpty) {
    final countMap = jsonField.first as Map<String, dynamic>?;
    return countMap?['count'] as int? ?? 0;
  }
  return 0;
}

class Profile {
  final String id;
  late final RxString username;
  late final RxString fullName;
  late final RxString avatarUrl;
  final DateTime createdAt;
  late final RxInt followerCount;
  late final RxInt followingCount;
  late final RxInt postCount;

  Profile({
    required this.id,
    required String initialUsername,
    required String initialFullName,
    required String initialAvatarUrl,
    required this.createdAt,
    required int initialFollowerCount,
    required int initialFollowingCount,
    required int initialPostCount,
  }) {
    username = initialUsername.obs;
    fullName = initialFullName.obs;
    avatarUrl = initialAvatarUrl.obs;
    followerCount = initialFollowerCount.obs;
    followingCount = initialFollowingCount.obs;
    postCount = initialPostCount.obs;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      initialUsername: json['username'] as String? ?? 'Vô danh',
      initialFullName: json['full_name'] as String? ?? '',
      initialAvatarUrl: json['avatar_url'] as String? ?? '',
      initialFollowerCount: _parseCount(json['follower_count']),
      initialFollowingCount: _parseCount(json['following_count']),
      initialPostCount: _parseCount(json['post_count']),
    );
  }
}
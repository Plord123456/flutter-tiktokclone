import 'package:get/get.dart';

int _parseCount(dynamic jsonField) {
  if (jsonField is List && jsonField.isNotEmpty) {
    return (jsonField.first as Map<String, dynamic>?)?['count'] as int? ?? 0;
  }
  return (jsonField as num?)?.toInt() ?? 0;
}

class Profile {
  final String id;
  final DateTime createdAt;

  late final RxString username;
  late final RxString fullName;
  late final RxString avatarUrl;
  late final RxInt postCount;
  late final RxInt followerCount;
  late final RxInt followingCount;

  Profile({
    required this.id,
    required this.createdAt,
    required String initialUsername,
    required String initialFullName,
    required String initialAvatarUrl,
    required int initialPostCount,
    required int initialFollowerCount,
    required int initialFollowingCount,
  }) {
    username = initialUsername.obs;
    fullName = initialFullName.obs;
    avatarUrl = initialAvatarUrl.obs;
    postCount = initialPostCount.obs;
    followerCount = initialFollowerCount.obs;
    followingCount = initialFollowingCount.obs;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      initialUsername: json['username'] ?? 'vô danh',
      initialFullName: json['full_name'] ?? '',
      initialAvatarUrl: json['avatar_url'] ?? '',
      initialPostCount: _parseCount(json['post_count']),
      initialFollowerCount: _parseCount(json['follower_count']),
      initialFollowingCount: _parseCount(json['following_count']),
    );
  }
}
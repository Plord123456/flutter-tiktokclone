import 'dart:convert';

class Profile {
  final String id;
  final String username;
  final String? fullName;
  final String avatarUrl;
  final DateTime createdAt;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int likesCount;

  Profile({
    required this.id,
    required this.username,
    this.fullName,
    required this.avatarUrl,
    required this.createdAt,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.likesCount,
  });

  Profile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    int? followerCount,
    int? followingCount,
    int? postCount,
    int? likesCount,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'follower_count': followerCount,
      'following_count': followingCount,
      'post_count': postCount,
      'likes_count': likesCount,
    };
  }

  /// ✅ SỬA LỖI: Đổi tên fromMap thành fromJson và đảm bảo nó nhận vào Map.
  /// Đây là cách làm đúng để tương thích với Supabase.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'Vô danh',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Profile(id: $id, username: $username, fullName: $fullName, avatarUrl: $avatarUrl, createdAt: $createdAt, followerCount: $followerCount, followingCount: $followingCount, postCount: $postCount, likesCount: $likesCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Profile &&
        other.id == id &&
        other.username == username &&
        other.fullName == fullName &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt &&
        other.followerCount == followerCount &&
        other.followingCount == followingCount &&
        other.postCount == postCount &&
        other.likesCount == likesCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    username.hashCode ^
    fullName.hashCode ^
    avatarUrl.hashCode ^
    createdAt.hashCode ^
    followerCount.hashCode ^
    followingCount.hashCode ^
    postCount.hashCode ^
    likesCount.hashCode;
  }
}

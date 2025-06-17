import 'package:get/get.dart';
import 'profile_model.dart';

class Video {
  final String id, videoUrl, title, thumbnailUrl;
  final DateTime createdAt;
  final Profile author;
  late final RxInt likeCount, commentCount;
  late final RxBool isLikedByCurrentUser, isFollowedByCurrentUser;

  Video({
    required this.id, required this.videoUrl, required this.title,
    required this.thumbnailUrl, required this.createdAt, required this.author,
    required int initialLikeCount, required int initialCommentCount,
    required bool initialIsLiked, required bool initialIsFollowed,
  }) {
    likeCount = initialLikeCount.obs;
    commentCount = initialCommentCount.obs;
    isLikedByCurrentUser = initialIsLiked.obs;
    isFollowedByCurrentUser = initialIsFollowed.obs;
  }

  factory Video.fromSupabase(Map<String, dynamic> json, {
    required String currentUserId, required bool isFollowed,
  }) {
    final likesData = json['likes'] as List? ?? [];
    final commentsCountData = json['comments_count'] as List? ?? [];
    if (json['profiles'] == null) {
      throw Exception('Video with id ${json['id']} is missing profile data.');
    }
    return Video(
      id: json['id'],
      videoUrl: json['video_url'],
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      author: Profile.fromJson(json['profiles']),
      initialLikeCount: likesData.length,
      initialCommentCount: commentsCountData.isNotEmpty ? commentsCountData.first['count'] : 0,
      initialIsLiked: currentUserId.isNotEmpty && likesData.any((like) => like['user_id'] == currentUserId),
      initialIsFollowed: isFollowed,
    );
  }
}
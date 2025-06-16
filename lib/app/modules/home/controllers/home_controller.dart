import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/follow_service.dart';
import '../../../data/models/comments_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/video_model.dart';

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;
  final Rxn<Profile> currentUser = Rxn<Profile>();
  final videoList = <Video>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  var canLoadMoreVideos = true.obs;
  final _videoPageSize = 5;
  final followService = Get.find<FollowService>();

  // --- Các biến cho Comment Sheet ---
  final comments = <Comment>[].obs;
  final commentTextController = TextEditingController();
  final isCommentLoading = false.obs;
  final isPostingComment = false.obs;
  final _commentPageSize = 10;
  var _commentCurrentPage = 0;
  var _canLoadMoreComments = true.obs;
  var _currentVideoIdForComments = ''.obs;
  final isPostButtonEnabled = false.obs;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    initialLoad();
    commentTextController.addListener(() {
      isPostButtonEnabled.value = commentTextController.text.trim().isNotEmpty;
    });
  }

  Future<void> initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchCurrentUserProfile(),
        fetchVideos(refresh: true),
      ]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    commentTextController.dispose();
    super.onClose();
  }

  Future<void> fetchCurrentUserProfile() async {
    if (currentUserId.isEmpty) return;
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUserId)
          .single();
      currentUser.value = Profile.fromJson(data);
    } catch (e) {
      print('Lỗi khi tải profile người dùng: $e');
    }
  }

  Future<void> fetchVideos({bool refresh = false}) async {
    if (refresh) {
      videoList.clear();
      canLoadMoreVideos.value = true;
    }

    try {
      final from = videoList.length;
      final to = from + _videoPageSize - 1;

      // ✅ SỬA LỖI QUAN TRỌNG NHẤT: Chỉ định rõ mối quan hệ cần dùng để join bảng `profiles`
      // theo gợi ý của Supabase để tránh lỗi "more than one relationship was found".
      final response = await supabase
          .from('videos')
          .select('''
            id, video_url, title, thumbnail_url, user_id, created_at,
            profiles!videos_user_id_fkey(id, username, avatar_url),
            likes(user_id),
            comments_count:comments(count)
          ''')
          .order('created_at', ascending: false)
          .range(from, to);

      final followedUserIds = followService.followedUserIds;
      final newVideos = _mapVideoResponse(response, followedUserIds);

      if (refresh) {
        videoList.assignAll(newVideos);
      } else {
        videoList.addAll(newVideos);
      }
      canLoadMoreVideos.value = newVideos.length == _videoPageSize;
    } catch (e) {
      print('Lỗi khi tải videos: ${e.toString()}');
      rethrow;
    }
  }

  List<Video> _mapVideoResponse(List<Map<String, dynamic>> response, Set<String> followedUserIds) {
    return response.map((item) {
      final profile = item['profiles'];
      if (profile == null) return null;

      final likes = item['likes'] as List;
      final commentsCountList = item['comments_count'] as List;
      final commentsCount = commentsCountList.isNotEmpty ? commentsCountList.first['count'] ?? 0 : 0;
      final isLiked = likes.any((like) => like['user_id'] == currentUserId);

      return Video(
        id: item['id'],
        videoUrl: item['video_url'],
        title: item['title'] ?? '',
        thumbnailUrl: item['thumbnail_url'] ?? '',
        username: profile['username'] ?? 'Unknown',
        profilePhoto: profile['avatar_url'] ?? '',
        postedById: item['user_id'],
        initialLikeCount: likes.length,
        initialCommentCount: commentsCount,
        initialIsLiked: isLiked,
        initialIsFollowed: followedUserIds.contains(item['user_id']),
        createdAt: DateTime.parse(item['created_at'] as String? ?? DateTime.now().toIso8601String()),
      );
    }).whereType<Video>().toList();
  }

  void _updateCommentCount(String videoId, {required bool increment}) {
    final video = videoList.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;
    if (increment) {
      video.commentCount.value++;
    } else if (video.commentCount.value > 0) {
      video.commentCount.value--;
    }
  }

  Future<void> fetchComments(String videoId, {bool refresh = false}) async {
    _currentVideoIdForComments.value = videoId;
    if (refresh) {
      comments.clear();
      _commentCurrentPage = 0;
      _canLoadMoreComments.value = true;
    }
    if (!_canLoadMoreComments.value) return;

    try {
      isCommentLoading.value = true;
      final from = _commentCurrentPage * _commentPageSize;
      final to = from + _commentPageSize - 1;

      // Chỉ định rõ join để tăng tính ổn định
      final data = await supabase
          .from('comments')
          .select('*, profiles!comments_user_id_fkey(username, avatar_url)')
          .eq('video_id', videoId)
          .order('created_at', ascending: false)
          .range(from, to);

      final newComments = data.map((json) => Comment.fromJson(json)).toList();
      comments.addAll(newComments);
      _canLoadMoreComments.value = newComments.length == _commentPageSize;
      _commentCurrentPage++;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải bình luận: ${e.toString()}');
    } finally {
      isCommentLoading.value = false;
    }
  }

  Future<void> postComment() async {
    if (isPostingComment.value) return;
    final content = commentTextController.text.trim();
    if (content.isEmpty || currentUserId.isEmpty) return;
    final videoId = _currentVideoIdForComments.value;
    if (videoId.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempComment = Comment(
      id: tempId,
      content: content,
      createdAt: DateTime.now(),
      userId: currentUserId,
      videoId: videoId,
      profile: currentUser.value,
      username: currentUser.value?.username ?? 'Bạn',
      avatarUrl: currentUser.value?.avatarUrl ?? '',
    );

    isPostingComment.value = true;
    commentTextController.clear();
    comments.insert(0, tempComment);
    _updateCommentCount(videoId, increment: true);

    try {
      final newCommentData = await supabase.from('comments').insert({
        'content': content,
        'video_id': videoId,
        'user_id': currentUserId,
      }).select('*, profiles!comments_user_id_fkey(username, avatar_url)').single();

      final realComment = Comment.fromJson(newCommentData);
      final index = comments.indexWhere((c) => c.id == tempId);
      if (index != -1) {
        comments[index] = realComment;
      }
    } catch (e) {
      comments.removeWhere((c) => c.id == tempId);
      _updateCommentCount(videoId, increment: false);
      Get.snackbar('Lỗi', 'Không thể đăng bình luận: ${e.toString()}');
    } finally {
      isPostingComment.value = false;
    }
  }

  Future<void> deleteComment(String commentId) async {
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;
    final commentToDelete = comments[index];
    comments.removeAt(index);
    _updateCommentCount(commentToDelete.videoId, increment: false);

    try {
      await supabase.from('comments').delete().eq('id', commentId);
    } catch (e) {
      comments.insert(index, commentToDelete);
      _updateCommentCount(commentToDelete.videoId, increment: true);
      Get.snackbar('Lỗi', 'Không thể xóa bình luận: ${e.toString()}');
    }
  }

  Future<void> loadMoreVideos() async {
    if (isLoadingMore.value || !canLoadMoreVideos.value) return;
    isLoadingMore.value = true;
    try {
      await fetchVideos(refresh: false);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải thêm video: ${e.toString()}');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void loadMoreComments() {
    if (!isCommentLoading.value && _canLoadMoreComments.value) {
      fetchComments(_currentVideoIdForComments.value);
    }
  }

  Future<void> toggleLike(String videoId) async {
    if (currentUserId.isEmpty) return;
    final video = videoList.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    final isCurrentlyLiked = video.isLikedByCurrentUser.value;
    video.isLikedByCurrentUser.value = !isCurrentlyLiked;
    video.likeCount.value += isCurrentlyLiked ? -1 : 1;

    try {
      if (isCurrentlyLiked) {
        await supabase.from('likes').delete().match({'video_id': videoId, 'user_id': currentUserId});
      } else {
        await supabase.from('likes').insert({'video_id': videoId, 'user_id': currentUserId});
      }
    } catch (e) {
      video.isLikedByCurrentUser.value = isCurrentlyLiked;
      video.likeCount.value += isCurrentlyLiked ? 1 : -1;
      Get.snackbar('Lỗi', 'Không thể cập nhật lượt thích.');
    }
  }

  void toggleFollow(String userId) {
    followService.toggleFollow(userId);
  }
}

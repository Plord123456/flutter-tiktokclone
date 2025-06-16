import 'dart:convert';
import '../../../../services/follow_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/media_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/video_model.dart';

class VideoUserController extends GetxController {
  final supabase = Supabase.instance.client;
  var profileUserId = ''.obs;
  var isLoading = true.obs;
  var userProfile = Rx<Profile?>(null);
  var videos = <Video>[].obs;
  var isFollowingRx = false.obs;
  var isMyProfile = false.obs;
  var hasMoreVideos = true.obs;
  var isLoadingMore = false.obs;
  var postCount = 0.obs;
  var currentPage = 0;
  final pageSize = 12;
  late final ScrollController scrollController;
  final FollowService _followService = Get.find();

  String? get currentUserId => supabase.auth.currentUser?.id;

  final RxSet<String> followedUserIds = <String>{}.obs;
  final RxSet<String> myLikedVideoIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent * 0.9) {
        fetchUserVideos();
      }
    });

    final argId = Get.arguments?['userId'] as String?;
    final cId = currentUserId;
    print('Received userId: $argId, currentUserId: $cId'); // Kiểm tra log

    if (cId == null && argId == null) {
      Get.snackbar('Error', 'Please log in to continue.');
      isLoading.value = false;
      return;
    }

    profileUserId.value = argId ?? cId!;
    print('Assigned profileUserId: ${profileUserId.value}'); // Log sau khi gán
    isMyProfile.value = (cId == profileUserId.value);
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchUserProfile(),
        fetchInitialFollowsAndLikes(),
        fetchPostCount(),
        if (!isMyProfile.value) checkFollowingStatus(),
      ]);
      await fetchUserVideos(isRefresh: true);
    } catch (e) {
      print("Lỗi trong fetchData: $e");
      Get.snackbar('Error', 'Failed to load profile data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> fetchInitialFollowsAndLikes() async {
    if (currentUserId == null) return;
    final followsFuture = supabase.from('follows').select('following_id').eq('follower_id', currentUserId!);
    final likesFuture = supabase.from('likes').select('video_id').eq('user_id', currentUserId!);

    final results = await Future.wait([followsFuture, likesFuture]);
    followedUserIds.value = (results[0] as List).map<String>((item) => item['following_id']).toSet();
    myLikedVideoIds.value = (results[1] as List).map<String>((item) => item['video_id']).toSet();
  }

  Future<void> fetchUserProfile() async {
    if (profileUserId.value.isEmpty) return;
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', profileUserId.value)
          .single();

      // SỬA LỖI: Bỏ jsonEncode và truyền thẳng Map 'response' vào
      userProfile.value = response != null ? Profile.fromJson(response) : null;

      print("Fetched userProfile for id: ${profileUserId.value}, result: ${userProfile.value?.username}");
    } catch (e) {
      print("Lỗi trong fetchUserProfile: $e");
      userProfile.value = null;
    }
  }

  Future<void> fetchUserVideos({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 0;
      videos.clear();
      hasMoreVideos.value = true;
    }

    if (isLoadingMore.value || !hasMoreVideos.value) return;

    if (!isRefresh) {
      isLoadingMore.value = true;
    }

    try {
      final from = currentPage * pageSize;
      final to = from + pageSize - 1;

      final response = await supabase
          .from('videos')
          .select('''
            id, user_id, title, video_url, created_at, thumbnail_url,
            profiles ( username, avatar_url ),
            likes ( count ),
            comments ( count )
          ''')
          .eq('user_id', profileUserId.value)
          .order('created_at', ascending: false)
          .range(from, to);

      final newVideos = (response as List).map((item) {
        final profileData = item['profiles'];
        if (profileData == null) return null;

        final likesList = item['likes'] as List;
        final likesCount = likesList.isNotEmpty ? (likesList.first['count'] ?? 0) : 0;

        final commentsList = item['comments'] as List;
        final commentCount = commentsList.isNotEmpty ? (commentsList.first['count'] ?? 0) : 0;

        final isLikedByMe = myLikedVideoIds.contains(item['id']);
        final isFollowed = followedUserIds.contains(item['user_id']);

        return Video(
          id: item['id'],
          videoUrl: item['video_url'],
          thumbnailUrl: item['thumbnail_url'] ?? '',
          title: item['title'] ?? '',
          username: profileData['full_name'] ?? profileData['username'] ?? 'Unknown User',
          profilePhoto: profileData['avatar_url'] ?? '',
          postedById: item['user_id'],
          initialLikeCount: likesCount,
          initialCommentCount: commentCount,
          initialIsLiked: isLikedByMe,
          initialIsFollowed: isFollowed,
        );
      }).whereType<Video>().toList();

      if (isRefresh) {
        videos.value = newVideos;
      } else {
        videos.addAll(newVideos);
      }

      if (newVideos.length < pageSize) {
        hasMoreVideos.value = false;
      }
      currentPage++;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load videos: ${e.toString()}');
    } finally {
      if (!isRefresh) {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> checkFollowingStatus() async {
    if (currentUserId == null || profileUserId.value.isEmpty) return;
    final response = await supabase
        .from('follows')
        .select()
        .eq('follower_id', currentUserId!)
        .eq('following_id', profileUserId.value)
        .limit(1);
    isFollowingRx.value = response.isNotEmpty;
  }

  Future<void> deleteVideo(String videoId, String videoUrl) async {
    if (currentUserId == null || !isMyProfile.value) {
      Get.snackbar('Error', 'You can only delete your own videos.');
      return;
    }
    final video = videos.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    final index = videos.indexOf(video);
    videos.removeAt(index);

    try {
      final path = Uri.parse(videoUrl).path.split('/videos/').last;
      await supabase.storage.from('videos').remove([path]);
      await supabase.from('videos').delete().eq('id', videoId);
      Get.snackbar('Success', 'Video deleted successfully!');
    } catch (e) {
      videos.insert(index, video);
      Get.snackbar('Error', 'Failed to delete video: ${e.toString()}');
    }
  }

  Future<void> toggleLike(String videoId) async {
    if (currentUserId == null) {
      Get.snackbar('Error', 'Please log in to like videos.');
      return;
    }

    final video = videos.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    final wasLiked = video.isLikedByCurrentUser.value;
    video.isLikedByCurrentUser.value = !wasLiked;
    video.likeCount.value += wasLiked ? -1 : 1;
    if (video.likeCount.value < 0) video.likeCount.value = 0;

    if (wasLiked) {
      myLikedVideoIds.remove(videoId);
    } else {
      myLikedVideoIds.add(videoId);
    }

    try {
      if (!wasLiked) {
        await supabase.from('likes').insert({'user_id': currentUserId!, 'video_id': videoId});
      } else {
        await supabase.from('likes').delete().match({'user_id': currentUserId!, 'video_id': videoId});
      }
    } catch (e) {
      video.isLikedByCurrentUser.value = wasLiked;
      video.likeCount.value += wasLiked ? 1 : -1;
      if (video.likeCount.value < 0) video.likeCount.value = 0;
      if (wasLiked) {
        myLikedVideoIds.add(videoId);
      } else {
        myLikedVideoIds.remove(videoId);
      }
      Get.snackbar('Error', 'Failed to update like status.');
    }
  }

  Future<void> fetchPostCount() async {
    if (profileUserId.value.isEmpty) return;
    final response = await supabase
        .from('videos')
        .select('id')
        .eq('user_id', profileUserId.value);
    postCount.value = response != null ? (response as List).length : 0;
  }

  Future<void> followUser() async {
    _followService.followUser(profileUserId.value);
    await fetchUserProfile();
  }

  Future<void> unfollowUser() async {
    _followService.unfollowUser(profileUserId.value);
    await fetchUserProfile();
  }

  bool get isFollowing => _followService.followedUserIds.contains(profileUserId.value);
}
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/app/modules/home/controllers/home_controller.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';
import 'package:tiktok_clone/services/follow_service.dart';
import 'package:tiktok_clone/widgets/comment_sheet.dart';

import '../app/modules/UserFeed/controllers/user_feed_controller.dart';

// ✅ BƯỚC 1: SỬA LẠI HOÀN TOÀN WIDGET NÀY

class VideoPlayerItem extends StatelessWidget {
  final Video video;
  final CachedVideoPlayerPlusController videoPlayerController;
  final int index; // Vẫn giữ index để biết video nào đang active

  const VideoPlayerItem({
    required this.video,
    required this.videoPlayerController,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Không còn Get.find<HomeController>() ở đây nữa

    // Nếu controller chưa sẵn sàng, hiện thumbnail và loading
    if (!videoPlayerController.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (video.thumbnailUrl.isNotEmpty)
            Image.network(video.thumbnailUrl, fit: BoxFit.cover),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }

    // Giao diện chính khi video đã sẵn sàng
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: videoPlayerController.value.aspectRatio,
              child: CachedVideoPlayerPlus(videoPlayerController),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.4]),
            ),
          ),
          // Nút Play/Pause ở giữa
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (videoPlayerController.value.isPlaying) {
                  videoPlayerController.pause();
                } else {
                  videoPlayerController.play();
                }
              },
              // AnimatedOpacity cần biết index của video nào đang chạy
              // Nhưng logic này nên nằm trong controller, ở đây ta đơn giản hóa
              // bằng cách chỉ dựa vào trạng thái isPlaying của chính video này.
              child: AnimatedOpacity(
                opacity: !videoPlayerController.value.isPlaying ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Icon(Iconsax.play,
                      color: Colors.white.withOpacity(0.7), size: 80),
                ),
              ),
            ),
          ),
          // Thông tin video
          Positioned(
            left: 16,
            right: 80,
            bottom: 60,
            child: _VideoInfoOverlay(video: video),
          ),
          // Các nút action bên phải
          _ActionButtonsColumn(video: video),
          // Thanh tiến trình video
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              videoPlayerController,
              allowScrubbing: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              colors: VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white.withOpacity(0.4),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Hãy tìm class _ActionButtonsColumn và thay thế nó bằng toàn bộ class này

class _ActionButtonsColumn extends StatelessWidget {
  final Video video;
  const _ActionButtonsColumn({required this.video});

  @override
  Widget build(BuildContext context) {
    final dynamic currentController = Get.isRegistered<UserFeedController>()
        ? Get.find<UserFeedController>()
        : Get.find<HomeController>();

    return Positioned(
      right: 10,
      bottom: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProfileAvatarButton(author: video.author),
          const SizedBox(height: 25),
          _LikeButton(
              onTap: () => currentController.toggleLike(video.id),
              isLiked: video.isLikedByCurrentUser,
              likeCount: video.likeCount),
          const SizedBox(height: 25),

          // NÚT COMMENT VỚI LOGIC ĐÚNG
          GestureDetector(
              onTap: () {
                currentController.pauseCurrentVideo();
                showCommentSheet(context, videoId: video.id);
                currentController.resumeCurrentVideo();
              },
              child: Obx(() => _ActionButton(
                  icon: Iconsax.message,
                  text: video.commentCount.value.toString()))),
          const SizedBox(height: 25),
          const _ActionButton(icon: Iconsax.send_1, text: 'Share'),
        ],
      ),
    );
  }
}
// Sửa lại _ProfileAvatarButton
class _ProfileAvatarButton extends StatelessWidget {
  final Profile author;
  const _ProfileAvatarButton({required this.author});

  @override
  Widget build(BuildContext context) {
    final FollowService followService = Get.find();
    // Tìm controller phù hợp
    final dynamic currentController = Get.isRegistered<UserFeedController>()
        ? Get.find<UserFeedController>()
        : Get.find<HomeController>();
    final bool isOwnVideo = author.id == currentController.currentUserId;

    return Column(children: [
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        GestureDetector(
          onTap: () {
            currentController.onPause();
            Get.toNamed(
              Routes.USER_PROFILE.replaceAll(':profileId', author.id),
            )?.then((_) {
              currentController.onResume();
            });
          },
          child: Obx(() => CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            backgroundImage: author.avatarUrl.value.isNotEmpty
                ? CachedNetworkImageProvider(author.avatarUrl.value)
                : null,
            child: author.avatarUrl.value.isEmpty
                ? const Icon(Iconsax.user, color: Colors.grey, size: 30)
                : null,
          )),
        ),
        if (!isOwnVideo)
          Obx(() => !followService.isFollowing(author.id)
              ? Positioned(
              bottom: -10,
              child: GestureDetector(
                  onTap: () => currentController.toggleFollow(author.id),
                  child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.black, width: 1.5)),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 16))))
              : const SizedBox.shrink()),
      ]),
    ]);
  }
}

class _LikeButton extends StatelessWidget {
  final VoidCallback onTap;
  final RxBool isLiked;
  final RxInt likeCount;
  const _LikeButton({required this.onTap, required this.isLiked, required this.likeCount});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Obx(() => _ActionButton(
        icon: isLiked.value ? Iconsax.heart5 : Iconsax.heart,
        text: likeCount.value.toString(),
        color: isLiked.value ? Colors.red.shade400 : Colors.white,
      )),
    );
  }
}

class _VideoInfoOverlay extends StatelessWidget {
  final Video video;
  const _VideoInfoOverlay({required this.video});
  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('@${video.author.username.value}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 1)])),
        if (video.title.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, shadows: [Shadow(blurRadius: 1)]))
        ]
      ],
    ));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ActionButton(
      {required this.icon, required this.text, this.color = Colors.white});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 5),
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/app/modules/home/controllers/home_controller.dart';
import '../app/routes/app_pages.dart';
import 'package:tiktok_clone/services/follow_service.dart';
import 'package:tiktok_clone/widgets/comment_sheet.dart';

// Constructor đã được dọn dẹp, chỉ còn video và index
class VideoPlayerItem extends StatelessWidget {
  final Video video;
  final int index;

  const VideoPlayerItem({
    required this.video,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    return GetBuilder<HomeController>(
      id: video.id,
      builder: (controller) {
        final videoPlayerController = controller.getControllerForIndex(index);

        if (videoPlayerController == null || !videoPlayerController.value.isInitialized) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (video.thumbnailUrl.isNotEmpty)
                Image.network(video.thumbnailUrl, fit: BoxFit.cover),
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            ],
          );
        }

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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.4]),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (videoPlayerController.value.isPlaying) {
                      videoPlayerController.pause();
                    } else {
                      videoPlayerController.play();
                    }
                  },
                  child: Obx(() => AnimatedOpacity(
                    opacity: controller.currentVideoIndex.value == index &&
                        !videoPlayerController.value.isPlaying
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Icon(Iconsax.play,
                          color: Colors.white.withOpacity(0.7), size: 80),
                    ),
                  )),
                ),
              ),
              Positioned(
                left: 16,
                right: 80,
                bottom: 60,
                child: _VideoInfoOverlay(video: video),
              ),
              _ActionButtonsColumn(video: video, homeController: homeController),
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
      },
    );
  }
}

class _ActionButtonsColumn extends StatelessWidget {
  final Video video;
  final HomeController homeController;
  const _ActionButtonsColumn(
      {required this.video, required this.homeController});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      bottom: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProfileAvatarButton(author: video.author, homeController: homeController),
          const SizedBox(height: 25),
          _LikeButton(
              onTap: () => homeController.toggleLike(video.id),
              isLiked: video.isLikedByCurrentUser,
              likeCount: video.likeCount),
          const SizedBox(height: 25),
          GestureDetector(
              onTap: () {
                homeController.getControllerForIndex(homeController.currentVideoIndex.value)?.pause();
                showCommentSheet(context, videoId: video.id);
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

class _ProfileAvatarButton extends StatelessWidget {
  final Profile author;
  final HomeController homeController;
  const _ProfileAvatarButton(
      {required this.author, required this.homeController});

  @override
  Widget build(BuildContext context) {
    final FollowService followService = Get.find();
    final bool isOwnVideo = author.id == homeController.currentUserId;
    return Column(children: [
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        GestureDetector(
          onTap: () => Get.toNamed(Routes.USER_FEED, arguments: author.id),
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
                  onTap: () => homeController.toggleFollow(author.id),
                  child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.black, width: 1.5)),
                      child:
                      const Icon(Icons.add, color: Colors.white, size: 16))))
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
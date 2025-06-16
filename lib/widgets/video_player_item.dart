import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/data/models/video_model.dart';
import '../app/modules/home/controllers/home_controller.dart';
import '../app/routes/app_pages.dart';
import 'comment_sheet.dart';

class VideoPlayerItem extends StatefulWidget {
  final Video video;
  const VideoPlayerItem({super.key, required this.video});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  final HomeController controller = Get.find();
  late CachedVideoPlayerPlusController _videoController;

  final isPlaying = false.obs;


  @override
  void initState() {
    super.initState();


    _videoController = CachedVideoPlayerPlusController.network(
      widget.video.videoUrl,
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
    )..initialize().then((_) {
      if (mounted) {
        _videoController.setLooping(true);
        setState(() {});
      }
    });

    _videoController.addListener(() {
      if (mounted) isPlaying.value = _videoController.value.isPlaying;
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() => isPlaying.value ? _videoController.pause() : _videoController.play();

  void _handleLike() {
    controller.toggleLike(widget.video.id);
  }

  void _handleCommentSheet() {
    // Tạm dừng video khi mở comment sheet
    _videoController.pause();
    showCommentSheet(context, videoId: widget.video.id);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.video.id),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        if (info.visibleFraction > 0.8 && !isPlaying.value) {
          _videoController.play();
        } else if (info.visibleFraction < 0.8 && isPlaying.value) {
          _videoController.pause();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildVideoPlayer(),
            _VideoInfoOverlay(video: widget.video),
            // ✅ SỬA LỖI: Truyền trực tiếp các thuộc tính Rx từ `widget.video`
            _ActionButtonsColumn(
              video: widget.video,
              onLike: _handleLike,
              onComment: _handleCommentSheet,
              likeCount: widget.video.likeCount,
              isLiked: widget.video.isLikedByCurrentUser,
              commentCount: widget.video.commentCount,
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildVideoProgressBar()),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_videoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: CachedVideoPlayerPlus(_videoController),
            ),
          ),
          Obx(() => isPlaying.value ? const SizedBox.shrink() : Icon(Icons.play_arrow, color: Colors.white.withOpacity(0.5), size: 80)),
        ],
      ),
    );
  }

  Widget _buildVideoProgressBar() => VideoProgressIndicator(
    _videoController,
    allowScrubbing: true,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    colors: VideoProgressColors(
      playedColor: Colors.red,
      bufferedColor: Colors.white.withOpacity(0.5),
      backgroundColor: Colors.white.withOpacity(0.2),
    ),
  );
}

// Các widget con không cần thay đổi vì chúng đã được thiết kế để nhận giá trị Rx.
class _ActionButtonsColumn extends StatelessWidget {
  final Video video;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final RxInt likeCount;
  final RxBool isLiked;
  final RxInt commentCount;

  const _ActionButtonsColumn({
    required this.video,
    required this.onLike,
    required this.onComment,
    required this.likeCount,
    required this.isLiked,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      bottom: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProfileAvatarButton(postedById: video.postedById, profilePhoto: video.profilePhoto),
          const SizedBox(height: 25),
          _LikeButton(onTap: onLike, isLiked: isLiked, likeCount: likeCount),
          const SizedBox(height: 25),
          GestureDetector(onTap: onComment, child: Obx(() => _ActionButton(icon: Iconsax.message, text: commentCount.value.toString()))),
          const SizedBox(height: 25),
          const _ActionButton(icon: Iconsax.send_1, text: 'Share'),
        ],
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  final String postedById;
  final String profilePhoto;
  final HomeController controller = Get.find();

  _ProfileAvatarButton({required this.postedById, required this.profilePhoto});

  @override
  Widget build(BuildContext context) {
    final bool isOwnVideo = postedById == controller.currentUserId;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () {
            print('Navigating to VIDEO_USER with userId: $postedById');
            Get.toNamed(Routes.VIDEO_USER, arguments: {'userId': postedById});
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            backgroundImage: profilePhoto.isNotEmpty
                ? NetworkImage(profilePhoto)
                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
          ),
        ),
        if (!isOwnVideo)
          Obx(() => !controller.followService.isFollowing(postedById)
              ? Positioned(
            bottom: -10,
            child: GestureDetector(
              onTap: () => controller.toggleFollow(postedById),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          )
              : const SizedBox.shrink()),
      ],
    );
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
        icon: isLiked.value ? Icons.favorite : Iconsax.heart,
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
    return Positioned(
      left: 16,
      right: 80,
      bottom: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('@${video.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          Text(video.title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ActionButton({required this.icon, required this.text, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 35, color: color),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

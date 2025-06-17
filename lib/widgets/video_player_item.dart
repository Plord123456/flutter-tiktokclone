import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ BƯỚC 3: IMPORT CÁC MODEL VÀ CONTROLLER THẬT
import '../app/data/models/video_model.dart';
import '../app/data/models/profile_model.dart';
import '../app/modules/home/controllers/home_controller.dart';
import '../app/modules/video_user/views/video_user_view.dart';

// ✅ BƯỚC 2: TOÀN BỘ PHẦN MOCK DATA ĐÃ ĐƯỢC XÓA BỎ

// Function to show a mock comment sheet (Giữ lại nếu bạn vẫn cần)
void showCommentSheet(BuildContext context, {required String videoId}) {
  // ... (code không đổi)
}

class VideoPlayerItem extends StatefulWidget {
  final Video video;
  const VideoPlayerItem({super.key, required this.video});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  // ✅ BƯỚC 3: SỬA LẠI CÁCH LẤY CONTROLLER
  // Dùng Get.find() để lấy controller đã được khởi tạo từ trước (trong Bindings)
  // thay vì tạo ra một MockHomeController mới.
  final HomeController controller = Get.find<HomeController>();

  late CachedVideoPlayerPlusController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = CachedVideoPlayerPlusController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          _videoController.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() => _videoController.value.isPlaying ? _videoController.pause() : _videoController.play();

  void _handleLike() => controller.toggleLike(widget.video.id);

  void _handleCommentSheet() {
    _videoController.pause();
    showCommentSheet(context, videoId: widget.video.id);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.video.id),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final isVisible = info.visibleFraction > 0.8;
        if (isVisible && !_videoController.value.isPlaying) {
          _videoController.play();
        } else if (!isVisible && _videoController.value.isPlaying) {
          _videoController.pause();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          _buildVideoPlayer(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                begin: Alignment.bottomCenter, end: Alignment.center,
              ),
            ),
          ),
          Positioned.fill(child: GestureDetector(onTap: _togglePlayPause)),
          Positioned(
            left: 16, right: 80, bottom: 60,
            child: _VideoInfoOverlay(video: widget.video),
          ),
          _ActionButtonsColumn(
            video: widget.video, onLike: _handleLike, onComment: _handleCommentSheet,
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildVideoProgressBar()),
        ]),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return ValueListenableBuilder(
      valueListenable: _videoController,
      builder: (context, CachedVideoPlayerPlusValue value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: CachedVideoPlayerPlus(_videoController),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            if (value.isInitialized)
              AnimatedOpacity(
                opacity: value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Iconsax.play, color: Colors.white.withOpacity(0.7), size: 80),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVideoProgressBar() => VideoProgressIndicator(
    _videoController,
    allowScrubbing: true,
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    colors: VideoProgressColors(
      playedColor: Colors.white,
      bufferedColor: Colors.white.withOpacity(0.4),
      backgroundColor: Colors.white.withOpacity(0.2),
    ),
  );
}

class _ActionButtonsColumn extends StatelessWidget {
  final Video video;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _ActionButtonsColumn({required this.video, required this.onLike, required this.onComment});

  @override
  Widget build(BuildContext context) {
    // Lấy controller bằng Get.find() để gọi hàm toggleFollow
    final HomeController controller = Get.find<HomeController>();

    return Positioned(
      right: 10, bottom: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Truyền hàm toggleFollow vào
          _ProfileAvatarButton(author: video.author, isFollowed: video.isFollowedByCurrentUser, onFollow: () => controller.toggleFollow(video.author.id)),
          const SizedBox(height: 25),
          _LikeButton(onTap: onLike, isLiked: video.isLikedByCurrentUser, likeCount: video.likeCount),
          const SizedBox(height: 25),
          GestureDetector(onTap: onComment, child: Obx(() => _ActionButton(icon: Iconsax.message, text: video.commentCount.value.toString()))),
          const SizedBox(height: 25),
          const _ActionButton(icon: Iconsax.send_1, text: 'Share'),
        ],
      ),
    );
  }
}

class _ProfileAvatarButton extends GetView<HomeController> {
  final Profile author;
  final RxBool isFollowed;
  final VoidCallback onFollow;

  const _ProfileAvatarButton({required this.author, required this.isFollowed, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    // So sánh trực tiếp, không cần .value
    final bool isOwnVideo = author.id == controller.currentUserId;
    return Column(children: [
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        GestureDetector(
          onTap: () => Get.toNamed('/user', arguments: author.id),          child: Obx(() => CircleAvatar(
            radius: 25, backgroundColor: Colors.white,
            backgroundImage: author.avatarUrl.value.isNotEmpty ? CachedNetworkImageProvider(author.avatarUrl.value) : null,
            child: author.avatarUrl.value.isEmpty ? const Icon(Iconsax.user, color: Colors.grey, size: 30) : null,
          )),
        ),
        if (!isOwnVideo)
          Obx(() => !isFollowed.value
              ? Positioned(bottom: -10, child: GestureDetector(onTap: onFollow, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)), child: const Icon(Icons.add, color: Colors.white, size: 16))))
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
        Text('@${video.author.username.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, shadows: [Shadow(blurRadius: 1)])),
        if (video.title.isNotEmpty) ...[const SizedBox(height: 8), Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 1)]))]
      ],
    ));
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
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
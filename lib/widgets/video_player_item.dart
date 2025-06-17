import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../app/modules/home/controllers/home_controller.dart';

// --- Mock Data and Controllers for Standalone Example ---
// In a real app, you would use your actual models and controllers.

class MockHomeController extends GetxController {
  final currentUserId = 'user-123'.obs;
  final followService = MockFollowService();

  void toggleLike(String videoId) {
    debugPrint('Toggled like for video $videoId');
    final video = videos.firstWhere((v) => v.id == videoId);
    video.isLikedByCurrentUser.toggle();
    if (video.isLikedByCurrentUser.value) {
      video.likeCount.value++;
    } else {
      video.likeCount.value--;
    }
  }

  void toggleFollow(String authorId) {
    debugPrint('Toggled follow for author $authorId');
    followService.toggleFollow(authorId);
  }

  // Example video list
  static final RxList<Video> videos = [
    Video(
      id: 'video1',
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      title: 'A beautiful bee on a flower.',
      likeCount: 1024.obs,
      commentCount: 512.obs,
      isLikedByCurrentUser: false.obs,
      author: Profile(
        id: 'author1',
        username: 'naturelover'.obs,
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop'.obs,
      ),
    ),
  ].obs;
}

class MockFollowService extends GetxController {
  final _following = <String>{}.obs;
  bool isFollowing(String userId) => _following.contains(userId);
  void toggleFollow(String userId) {
    if (isFollowing(userId)) {
      _following.remove(userId);
    } else {
      _following.add(userId);
    }
  }
}

// Your data models
class Profile {
  final String id;
  final RxString username;
  final RxString avatarUrl;
  Profile({required this.id, required this.username, required this.avatarUrl});
}

class Video {
  final String id;
  final String videoUrl;
  final String title;
  final RxInt likeCount;
  final RxInt commentCount;
  final RxBool isLikedByCurrentUser;
  final Profile author;
  Video({
    required this.id, required this.videoUrl, required this.title,
    required this.likeCount, required this.commentCount,
    required this.isLikedByCurrentUser, required this.author,
  });
}

// --- End Mock Data ---


// Function to show a mock comment sheet
void showCommentSheet(BuildContext context, {required String videoId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Comments for $videoId',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: Center(
                child: Text('Comments would appear here.', style: TextStyle(color: Colors.grey[400])),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


// --- Your Refactored Widget ---

class VideoPlayerItem extends StatefulWidget {
  final Video video;
  const VideoPlayerItem({super.key, required this.video});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  final HomeController controller = Get.put(MockHomeController() as HomeController);
  late CachedVideoPlayerPlusController _videoController;

  // REMOVED: isPlaying.obs to prevent state conflicts.
  // We will now get the playing state directly from the video controller.

  @override
  void initState() {
    super.initState();
    _videoController = CachedVideoPlayerPlusController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        // Using `ValueListenableBuilder` now, so no need for setState here.
        if (mounted) {
          _videoController.setLooping(true);
        }
      });

    // REMOVED: The listener that was causing the "setState during build" error.
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  // UPDATED: This now checks the controller's value directly.
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
        // Use the controller's value to check the playing state.
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
          // Overlay gradient for better text visibility.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                begin: Alignment.topCenter, end: Alignment.center,
              ),
            ),
          ),
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

  // REFACTORED: This widget now uses a ValueListenableBuilder.
  // This is the idiomatic Flutter way to rebuild a widget based on a
  // controller's state without causing "setState during build" errors.
  Widget _buildVideoPlayer() {
    return ValueListenableBuilder(
      valueListenable: _videoController,
      builder: (context, CachedVideoPlayerPlusValue value, child)  {
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

            // The play/pause icon's visibility is now safely handled by the builder.
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
    return Positioned(
      right: 10, bottom: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProfileAvatarButton(author: video.author),
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
  const _ProfileAvatarButton({required this.author});

  @override
  Widget build(BuildContext context) {
    final bool isOwnVideo = author.id == controller.currentUserId;
    return Column(children: [
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        GestureDetector(
          onTap: () => debugPrint('Navigate to profile ${author.id}'), // Replaced Get.toNamed for standalone example
          child: Obx(() => CircleAvatar(
            radius: 25, backgroundColor: Colors.white,
            backgroundImage: author.avatarUrl.value.isNotEmpty ? CachedNetworkImageProvider(author.avatarUrl.value) : null,
            child: author.avatarUrl.value.isEmpty ? const Icon(Iconsax.user, color: Colors.grey, size: 30) : null,
          )),
        ),
        if (!isOwnVideo)
          Obx(() => !controller.followService.isFollowing(author.id)
              ? Positioned(bottom: -10, child: GestureDetector(onTap: () => controller.toggleFollow(author.id), child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)), child: const Icon(Icons.add, color: Colors.white, size: 16))))
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

import '../app/data/models/comments_model.dart';
import '../app/modules/comment_sheet/comment_controller.dart';

// Hàm để hiển thị bottom sheet
void showCommentSheet(BuildContext context, {required String videoId}) {
  Get.lazyPut(() => CommentController(videoId: videoId));

  Get.bottomSheet(
    const CommentSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  ).whenComplete(() {
    Get.delete<CommentController>();
  });
}

// Widget chính của Bottom Sheet
class CommentSheet extends GetView<CommentController> {
  const CommentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      // Chiều cao linh hoạt, tránh bị keyboard che khuất
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Co lại theo nội dung
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // FIX: Sử dụng getter mới để hiển thị tổng số bình luận
                Obx(() => Text(
                  '${controller.totalCommentCount} bình luận',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                )),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách bình luận
          Flexible( // Dùng Flexible thay cho Expanded khi Column có mainAxisSize.min
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.comments.isEmpty) {
                return const Center(
                  child: Text(
                    'Chưa có bình luận nào.\nHãy là người đầu tiên!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                controller: controller.scrollController,
                itemCount: controller.comments.length,
                padding: const EdgeInsets.all(8.0),
                itemBuilder: (context, index) => CommentItem(
                  comment: controller.comments[index],
                ),
              );
            }),
          ),

          // Ô nhập liệu
          _buildCommentInputField(context, theme),
        ],
      ),
    );
  }

  Widget _buildCommentInputField(BuildContext context, ThemeData theme) {
    return Obx(() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.replyingTo.value != null)
          Container(
            color: theme.hoverColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Đang trả lời ${controller.replyingTo.value!.username}"),
                InkWell(
                  onTap: controller.cancelReply,
                  child: const Icon(Icons.close, size: 16),
                )
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.textController,
                  enabled: !controller.isPostingComment.value,
                  decoration: InputDecoration(
                    hintText: 'Thêm bình luận...',
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) {
                    if (!controller.isPostingComment.value) {
                      controller.addComment();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => IconButton.filled(
                onPressed: controller.isPostingComment.value ? null : controller.addComment,
                icon: controller.isPostingComment.value
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                )
                    : const Icon(Icons.send),
              )),
            ],
          ),
        ),
      ],
    ));
  }
}

// Widget cho mỗi item bình luận
class CommentItem extends GetView<CommentController> {
  final Comment comment;
  final double indentation;

  const CommentItem({super.key, required this.comment, this.indentation = 0.0});

  void _showOptions(BuildContext context) {
    Get.bottomSheet(
      Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Iconsax.message_edit),
            title: const Text('Trả lời'),
            onTap: () {
              Get.back();
              controller.startReply(comment);
            },
          ),
          if (controller.currentUserId == comment.userId)
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text('Xóa bình luận', style: TextStyle(color: Colors.red)),
              onTap: () => controller.deleteComment(comment.id),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // IMPROVEMENT: Thêm Obx để hiển thị trạng thái đang xóa
    return Obx(() {
      if (controller.deletingCommentIds.contains(comment.id)) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: EdgeInsets.only(left: indentation),
          child: const Row(children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 16),
            Text("Đang xóa..."),
          ]),
        );
      }
      return Padding(
        padding: EdgeInsets.only(left: indentation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onLongPress: () => _showOptions(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(

                      radius: 18,
                      backgroundImage: comment.avatarUrl.value.isNotEmpty ? CachedNetworkImageProvider(comment.avatarUrl.value) : null,
                      child: comment.avatarUrl.isEmpty ? Text(comment.username.value.isNotEmpty ? comment.username.value[0].toUpperCase() : '') : null,                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.username.value, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),                          const SizedBox(height: 2),
                          Text(comment.content, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                DateFormat.yMd().add_jm().format(comment.createdAt.toLocal()),
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(width: 16),
                              InkWell(
                                onTap: () => controller.startReply(comment),
                                child: Text('Trả lời', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Obx(() => Column(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            comment.isLiked.value ? Iconsax.heart5 : Iconsax.heart,
                            color: comment.isLiked.value ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                          onPressed: () => controller.toggleLike(comment.id),
                        ),
                        Text(
                          comment.likeCount.value.toString(),
                          style: theme.textTheme.labelSmall,
                        )                      ],
                    )),
                  ],
                ),
              ),
            ),
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comment.replies.length,
              itemBuilder: (context, index) => CommentItem(
                comment: comment.replies[index],
                indentation: 20.0,
              ),
            )),
          ],
        ),
      );
    });
  }
}
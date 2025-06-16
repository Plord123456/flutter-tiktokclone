import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../app/data/models/comments_model.dart';
import '../app/modules/comment_sheet/comment_controller.dart';

// ✅ SỬA LỖI: Chỉnh lại đường dẫn import cho đúng


// Hàm để hiển thị bottom sheet
void showCommentSheet(BuildContext context, {required String videoId}) {
  // Sử dụng Get.lazyPut để khởi tạo controller khi cần và truyền videoId vào
  Get.lazyPut(() => CommentController(videoId: videoId));

  Get.bottomSheet(
    // ✅ SỬA LỖI: Không cần truyền videoId vào widget nữa vì nó đã có trong controller
    const CommentSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  ).whenComplete(() {
    // Xóa controller khi sheet được đóng để giải phóng bộ nhớ
    Get.delete<CommentController>();
  });
}

// ✅ SỬA LỖI: Widget này kế thừa controller qua GetView, không cần nhận tham số
class CommentSheet extends GetView<CommentController> {
  const CommentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
                Obx(() => Text(
                  '${controller.comments.length} bình luận',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                )),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách bình luận với các trạng thái
          Expanded(
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

          // Ô nhập liệu với trạng thái đang gửi
          Obx(() => Column(
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
                padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        enabled: !controller.isPostingComment.value,
                        decoration: InputDecoration(
                          hintText: 'Thêm bình luận...',
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
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
          )),
        ],
      ),
    );
  }
}

// Widget CommentItem không có thay đổi, giữ nguyên như cũ
// ... (Dán widget CommentItem vào đây) ...
class CommentItem extends GetView<CommentController> {
  final Comment comment;
  final double indentation;

  const CommentItem({super.key, required this.comment, this.indentation = 0.0});

  void _showOptions(BuildContext context) {
    Get.bottomSheet(
        Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Trả lời'),
                onTap: () {
                  Get.back();
                  controller.startReply(comment);
                },
              ),
              if (controller.currentUserId == comment.userId)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Xóa bình luận', style: TextStyle(color: Colors.red)),
                  onTap: () => controller.deleteComment(comment.id),
                ),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onLongPress: () => _showOptions(context),
            onTap: () {}, // Để hiệu ứng ripple hoạt động
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: comment.avatarUrl.isNotEmpty
                        ? NetworkImage(comment.avatarUrl)
                        : null,
                    child: comment.avatarUrl.isEmpty ? Text(comment.username[0].toUpperCase()) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.username, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(comment.content, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormat('d/M/yy').format(comment.createdAt),
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
                  Obx(() => IconButton(
                    icon: Icon(
                      comment.isLiked.value ? Icons.favorite : Icons.favorite_border,
                      color: comment.isLiked.value ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                    onPressed: () => controller.toggleLike(comment.id),
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
              indentation: indentation + 20.0,
            ),
          )),
        ],
      ),
    );
  }
}
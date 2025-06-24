import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiktok_clone/app/data/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/chat_detail_controller.dart';

class ChatDetailView extends GetView<ChatDetailController> {
  const ChatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy ID người dùng hiện tại một cách an toàn
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      // Xử lý trường hợp người dùng chưa đăng nhập, có thể hiển thị một màn hình lỗi hoặc quay về trang đăng nhập
      return const Scaffold(
        body: Center(
          child: Text("Lỗi: Người dùng chưa đăng nhập."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(

        title: Obx(() => Text(controller.conversation.value.otherUserUsername ?? 'Chat')),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.messages.isEmpty) {
                return const Center(
                  child: Text("Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện!"),
                );
              }
              return ListView.builder(
                reverse: true,
                controller: controller.scrollController,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  // So sánh an toàn, tránh trường hợp currentUserId là null
                  final isMe = message.senderId == currentUserId;
                  return _MessageBubble(
                    message: message,
                    isMe: isMe,
                    onReply: () => controller.setReplyingTo(message),
                  );
                },
              );
            }),
          ),
          _MessageInputField(),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onReply,
  });

  String formatTimestamp(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(message.id),
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => onReply(),
            backgroundColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            foregroundColor: Colors.white,
            icon: Icons.reply,
            label: 'Trả lời',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Kiểm tra nếu có tin nhắn được trả lời thì hiển thị preview
            if (message.repliedToMessage != null)
              _RepliedMessagePreview(
                // Dùng `!` vì đã kiểm tra null ở trên
                  message: message.repliedToMessage!,
                  isMe: isMe),
            Row(
              mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                          : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 10, right: 10),
              child: Text(
                formatTimestamp(message.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepliedMessagePreview extends StatelessWidget {
  final Message message;
  final bool isMe; // isMe của tin nhắn hiện tại, không phải tin nhắn được reply

  const _RepliedMessagePreview({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isReplyingToMyOwnMessage = message.senderId == currentUserId;


    final String authorUsername = message.sender?.username ?? 'Người dùng';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isMe ? Colors.blue.shade50 : Colors.grey.shade100).withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(
              color: isReplyingToMyOwnMessage
                  ? Theme.of(context).colorScheme.primary
                  : Colors.green,
              width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReplyingToMyOwnMessage ? 'Bạn' : authorUsername,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isReplyingToMyOwnMessage
                  ? Theme.of(context).colorScheme.primary
                  : Colors.green,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}


class _MessageInputField extends GetView<ChatDetailController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (controller.replyingToMessage.value == null) {
              return const SizedBox.shrink();
            }
            final message = controller.replyingToMessage.value!;
            // Tương tự, lấy username một cách an toàn
            final replyingToUsername = (message.senderId == Supabase.instance.client.auth.currentUser!.id)
                ? 'chính bạn'
                : message.sender?.username ?? 'một người dùng';

            return Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Đang trả lời ${replyingToUsername}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text(message.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: controller.cancelReply,
                  )
                ],
              ),
            );
          }),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => controller.sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(50),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: controller.sendMessage,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

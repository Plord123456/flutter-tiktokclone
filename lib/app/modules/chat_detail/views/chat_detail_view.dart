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
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.conversation.otherUserUsername ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                reverse: true,
                controller: controller.scrollController,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
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

  String formatTimestamp(DateTime dt) => DateFormat('HH:mm').format(dt);

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
            if (message.repliedToMessage != null)
              _RepliedMessagePreview(
                  message: message.repliedToMessage!, isMe: isMe),
            Row(
              mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(message.content),
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
  final bool isMe;

  const _RepliedMessagePreview({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // V SỬA: Khai báo rõ ràng kiểu dữ liệu của authorUsername
    final String authorUsername = message.sender?.username ?? '...';
    final isReplyingToMyOwnMessage =
        message.senderId == Supabase.instance.client.auth.currentUser!.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 1, right: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
        (isMe ? Colors.blue.shade50 : Colors.grey.shade100).withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(
              color: isReplyingToMyOwnMessage ? Colors.blue : Colors.green,
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
              color: isReplyingToMyOwnMessage ? Colors.blue : Colors.green,
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
            if (controller.replyingToMessage.value == null)
              return const SizedBox.shrink();
            final message = controller.replyingToMessage.value!;
            return Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Đang trả lời ${message.sender?.username ?? 'chính bạn'}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(message.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: controller.cancelReply)
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
                IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: controller.sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// lib/app/modules/chat/chat_list/views/chat_list_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../controllers/chat_list_controller.dart';

class ChatListView extends GetView<ChatListController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Cài đặt ngôn ngữ cho timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        centerTitle: true,
      ),
      body: Obx(
            () {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.conversations.isEmpty) {
            return const Center(child: Text('Chưa có cuộc trò chuyện nào.'));
          }
          // Dùng RefreshIndicator để người dùng có thể vuốt xuống để tải lại
          return RefreshIndicator(
            onRefresh: controller.fetchConversations,
            child: ListView.builder(
              itemCount: controller.conversations.length,
              itemBuilder: (context, index) {
                final conversation = controller.conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: CachedNetworkImageProvider(
                      // Lấy avatar của người đối diện
                      conversation.otherParticipant.avatarUrl.value,
                    ),
                    // Fallback nếu không có avatar
                    child: conversation.otherParticipant.avatarUrl.value.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    // Lấy username của người đối diện
                    conversation.otherParticipant.username.value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    conversation.lastMessageContent ?? 'Bắt đầu trò chuyện ngay!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    conversation.lastMessageCreatedAt != null
                    // Hiển thị thời gian dạng "5 phút trước", "1 giờ trước"
                        ? timeago.format(conversation.lastMessageCreatedAt!, locale: 'vi')
                        : '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => controller.navigateToChatDetail(conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
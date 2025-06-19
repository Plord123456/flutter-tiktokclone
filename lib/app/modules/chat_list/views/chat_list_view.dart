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
          return RefreshIndicator(
            onRefresh: controller.fetchConversations,
            child: ListView.builder(
              itemCount: controller.conversations.length,
              itemBuilder: (context, index) {
                final conversation = controller.conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      conversation.otherParticipant.avatarUrl?.value ?? '',
                    ),
                    child: conversation.otherParticipant.avatarUrl?.value == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
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
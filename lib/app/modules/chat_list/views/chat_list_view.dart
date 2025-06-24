import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';
import '../controllers/chat_list_controller.dart';

class ChatListView extends GetView<ChatListController> {
  const ChatListView({super.key});

  String formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return DateFormat('HH:mm').format(dt);
    return DateFormat('dd/MM/yy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.conversations.isEmpty) {
          return const Center(child: Text('Chưa có cuộc trò chuyện nào.'));
        }
        return SmartRefresher(
          controller: controller.refreshController,
          onRefresh: controller.onRefresh,
          header: const WaterDropHeader(),
          child: ListView.builder(
            itemCount: controller.conversations.length,
            itemBuilder: (context, index) {
              final conversation = controller.conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    conversation.otherUserAvatarUrl ?? 'https://placehold.co/100',
                  ),
                ),
                title: Text(
                  conversation.otherUserUsername ?? 'Người dùng',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  conversation.lastMessageContent ?? '...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  formatTimestamp(conversation.lastMessageCreatedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Get.toNamed(Routes.CHAT_DETAIL, arguments: conversation);
                },
              );
            },
          ),
        );
      }),
    );
  }
}

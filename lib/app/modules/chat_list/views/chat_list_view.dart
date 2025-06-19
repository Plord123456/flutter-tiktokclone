import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/chat_list_controller.dart';

class ChatListView extends GetView<ChatListController> {
  const ChatListView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatListView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'ChatListView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// lib/app/modules/chat/chat_detail/controllers/chat_detail_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/data/models/message_model.dart';
import 'package:tiktok_clone/services/chat_service.dart';

import '../../../../services/auth_service.dart';

class ChatDetailController extends GetxController {
  final ChatService _chatService = Get.find();
  final AuthService _authService = Get.find();
  final supabase = Supabase.instance.client;

  // Trạng thái chung
  final isLoading = true.obs;
  late final Rx<Conversation> conversation;
  final messageInputController = TextEditingController();
  final scrollController = ScrollController();

  // Dữ liệu tin nhắn
  final messages = <Message>[].obs;
  // THAY ĐỔI 1: Kiểu dữ liệu của subscription đã thay đổi
  late final StreamSubscription messageSubscription;

  String get currentUserId => _authService.currentUserId;

  @override
  void onInit() {
    super.onInit();
    // Gán arguments trong onInit để đảm bảo an toàn
    conversation = Rx<Conversation>(Get.arguments);
  }

  @override
  void onReady() {
    super.onReady();
    _init();
  }

  Future<void> _init() async {
    await fetchMessages();
    setupSubscription();
  }

  Future<void> fetchMessages() async {
    try {
      isLoading(true);
      final result = await _chatService.getMessages(conversation.value.id);
      messages.assignAll(result);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải tin nhắn');
    } finally {
      isLoading(false);
    }
  }

  void setupSubscription() {
    messageSubscription = _chatService.subscribeToMessages(
      conversation.value.id,
          (newMessage) {
        // Kiểm tra xem tin nhắn đã có trong list chưa để tránh trùng lặp
        if (!messages.any((m) => m.id == newMessage.id)) {
          messages.insert(0, newMessage);
        }
      },
    );
  }

  Future<void> sendMessage() async {
    final content = messageInputController.text;
    if (content.isEmpty) return;

    messageInputController.clear();
    await _chatService.sendMessage(conversation.value.id, content);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    messageInputController.dispose();
    scrollController.dispose();
    messageSubscription.cancel();
    super.onClose();
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/data/models/message_model.dart';
import 'package:tiktok_clone/services/auth_service.dart'; // V THÊM IMPORT
import 'package:tiktok_clone/services/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatDetailController extends GetxController {
  final ChatService _chatService = Get.find();
  // V SỬA: Thêm AuthService
  final AuthService _authService = Get.find();
  late final Conversation conversation;

  var messages = <Message>[].obs;
  var isLoading = true.obs;
  final textController = TextEditingController();
  final scrollController = ScrollController();
  var replyingToMessage = Rxn<Message>();
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    conversation = Get.arguments as Conversation;
    _fetchMessages();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages(isPolling: true));
  }

  Future<void> _fetchMessages({bool isPolling = false}) async {
    if (!isPolling) isLoading.value = true;
    try {
      final result = await _chatService.getMessages(conversation.id);
      if (result.length != messages.length || isPolling) {
        messages.assignAll(result);
      }
    } finally {
      if (!isPolling) isLoading.value = false;
    }
  }

  Future<void> sendMessage() async {
    final content = textController.text.trim();
    if (content.isEmpty) return;

    final tempMessage = Message(
      id: const Uuid().v4(),
      conversationId: conversation.id,
      // V SỬA: Lấy ID người gửi từ AuthService
      senderId: _authService.currentUserId,
      content: content,
      createdAt: DateTime.now(),
      // V SỬA: Lấy profile người gửi từ AuthService để hiển thị tạm
      sender: _authService.userProfile.value,
      repliedToMessage: replyingToMessage.value,
    );

    messages.insert(0, tempMessage);

    final messageToSend = content;
    final String? replyId = replyingToMessage.value?.id;

    textController.clear();
    cancelReply();

    await _chatService.sendMessage(
      conversationId: conversation.id,
      content: messageToSend,
      replyToMessageId: replyId,
    );

    await _fetchMessages(isPolling: true);
  }

  void setReplyingTo(Message message) {
    replyingToMessage.value = message;
  }

  void cancelReply() {
    replyingToMessage.value = null;
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    _pollingTimer?.cancel();
    super.onClose();
  }
}

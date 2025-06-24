import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/data/models/message_model.dart';
import 'package:tiktok_clone/services/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatDetailController extends GetxController {
  final ChatService _chatService = Get.find();
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages(isPolling: true));
  }

  Future<void> _fetchMessages({bool isPolling = false}) async {
    if (!isPolling) isLoading.value = true;
    try {
      // Sửa: Đảm bảo conversation.id là String
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
      // Sửa: Đảm bảo conversation.id là String
      conversationId: conversation.id,
      senderId: _chatService.supabase.auth.currentUser!.id,
      content: content,
      createdAt: DateTime.now(),
      repliedToMessage: replyingToMessage.value,
      // Thêm sender tạm thời để UI hiển thị đúng avatar
      sender: _chatService.authService.userProfile.value,
    );

    messages.insert(0, tempMessage);

    final messageToSend = content;
    // Sửa: replyId giờ là String?
    final String? replyId = replyingToMessage.value?.id;

    textController.clear();
    cancelReply();

    await _chatService.sendMessage(
      // Sửa: Đảm bảo conversation.id là String
      conversationId: conversation.id,
      content: messageToSend,
      replyToMessageId: replyId, // Truyền String?
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

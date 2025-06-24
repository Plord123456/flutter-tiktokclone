import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/data/models/message_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatDetailController extends GetxController {
  final ChatService _chatService = Get.find();
  final AuthService _authService = Get.find();

  late final Rx<Conversation> conversation;

  var messages = <Message>[].obs;
  var isLoading = true.obs;
  final textController = TextEditingController();
  final scrollController = ScrollController();
  var replyingToMessage = Rxn<Message>();
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();

    // *** SỬA LỖI Ở ĐÂY (2/2) ***
    // Lấy đối tượng Conversation từ arguments và biến nó thành một
    // đối tượng reactive bằng cách thêm `.obs`.
    conversation = (Get.arguments as Conversation).obs;

    _fetchMessages();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages(isPolling: true));
  }

  Future<void> _fetchMessages({bool isPolling = false}) async {
    if (!isPolling) isLoading.value = true;
    try {
      // Truy cập ID từ .value vì 'conversation' bây giờ là một Rx<Conversation>
      final result = await _chatService.getMessages(conversation.value.id);
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

    // Truy cập ID từ .value
    final tempMessage = Message(
      id: const Uuid().v4(),
      conversationId: conversation.value.id,
      senderId: _authService.currentUserId,
      content: content,
      createdAt: DateTime.now(),
      sender: _authService.userProfile.value,
      repliedToMessage: replyingToMessage.value,
    );

    messages.insert(0, tempMessage);

    final messageToSend = content;
    final String? replyId = replyingToMessage.value?.id;

    textController.clear();
    cancelReply();

    await _chatService.sendMessage(
      // Truy cập ID từ .value
      conversationId: conversation.value.id,
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

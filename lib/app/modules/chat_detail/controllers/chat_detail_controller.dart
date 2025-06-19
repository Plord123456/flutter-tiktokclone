// lib/app/modules/chat/chat_detail/controllers/chat_detail_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/chat_service.dart';
import 'package:uuid/uuid.dart'; // Thêm thư viện để tạo ID tạm thời

class ChatDetailController extends GetxController {
  final ChatService _chatService = Get.find();
  final AuthService _authService = Get.find();

  // Trạng thái chung
  final isLoading = true.obs;
  late final Rx<Conversation> conversation;
  final messageInputController = TextEditingController();
  final scrollController = ScrollController();
  var uuid = const Uuid(); // Để tạo ID tạm

  // Dữ liệu tin nhắn
  final messages = <Message>[].obs;
  late final StreamSubscription messageSubscription;

  String get currentUserId => _authService.currentUserId;

  @override
  void onInit() {
    super.onInit();
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

  // Sửa lại logic xử lý payload
  void setupSubscription() {
    messageSubscription = _chatService.subscribeToMessages(
      conversation.value.id,
          (payload) {
        // Thay vì chỉ thêm, chúng ta sẽ xây dựng lại list messages từ payload
        // Điều này sẽ tự động xử lý cả Thêm, Sửa, và Xóa
        final newMessages = payload.map((record) => Message.fromJson(record)).toList();
        messages.assignAll(newMessages);
      },
    );
  }
  void confirmDeleteMessage(Message message) {
    // Chỉ cho phép xóa tin nhắn của chính mình
    if (message.senderId != currentUserId) return;

    Get.defaultDialog(
      title: "Xác nhận xóa",
      middleText: "Bạn có chắc chắn muốn xóa tin nhắn này không?",
      textConfirm: "Xóa",
      textCancel: "Hủy",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back(); // Đóng dialog
        _deleteMessageOptimistically(message);
      },
    );
  }
  Future<void> _deleteMessageOptimistically(Message message) async {
    // Optimistic UI: Xóa ngay trên UI để người dùng thấy kết quả tức thì
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages.removeAt(index);
    }

    try {
      // Gửi yêu cầu xóa lên server
      await _chatService.deleteMessage(message.id);
    } catch (e) {
      // Nếu có lỗi, khôi phục lại tin nhắn trên UI và thông báo
      if (index != -1) {
        messages.insert(index, message);
      }
      Get.snackbar('Lỗi', 'Không thể xóa tin nhắn. Vui lòng thử lại.');
    }
  }
  // Nâng cấp với Optimistic UI
  Future<void> sendMessage() async {
    final content = messageInputController.text.trim();
    if (content.isEmpty) return;

    final currentUserProfile = _authService.userProfile.value;
    if (currentUserProfile == null) return;

    messageInputController.clear();

    // == OPTIMISTIC UI: Cập nhật giao diện ngay lập tức ==
    // 1. Tạo một tin nhắn tạm với ID giả
    final tempId = uuid.v4();
    final tempMessage = Message(
      id: tempId,
      conversationId: conversation.value.id,
      senderId: currentUserId,
      content: content,
      createdAt: DateTime.now(),
      sender: currentUserProfile, // Sử dụng profile hiện tại để hiển thị avatar
    );

    // 2. Thêm ngay tin nhắn tạm này vào danh sách để người dùng thấy
    messages.insert(0, tempMessage);
    // Cuộn xuống cuối
    scrollToBottom();

    // 3. Gửi tin nhắn thật sự lên server (không cần await)
    // Server sẽ tự trả về qua realtime và cập nhật lại tin nhắn tạm
    try {
      await _chatService.sendMessage(conversation.value.id, content);
    } catch(e) {
      // Nếu gửi thất bại, xóa tin nhắn tạm và thông báo lỗi
      messages.removeWhere((m) => m.id == tempId);
      Get.snackbar('Lỗi', 'Không thể gửi tin nhắn.');
    }
  }

  void scrollToBottom() {
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
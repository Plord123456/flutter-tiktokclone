import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';
import 'package:tiktok_clone/services/chat_service.dart';

class ChatListController extends GetxController {
  final ChatService _chatService = Get.find();

  final isLoading = true.obs;
  final conversations = <Conversation>[].obs;

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  @override
  void onReady() {
    super.onReady();
    fetchConversations();
    _listenToNewMessages();
  }

  // ✅ BẮT ĐẦU PHẦN SỬA LỖI CÚ PHÁP
  void _listenToNewMessages() {
    // Lắng nghe tất cả các thay đổi trên bảng 'messages'
    // Đây là cú pháp cũ và ổn định hơn cho phiên bản của bạn
    _messagesSubscription = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      print('Bảng messages có thay đổi, cập nhật lại danh sách chat...');
      fetchConversations();
    })
      ..onError((e) => print('Lỗi lắng nghe real-time: $e'));
  }
  // ✅ KẾT THÚC PHẦN SỬA LỖI CÚ PHÁP

  @override
  void onClose() {
    // Hủy lắng nghe để tránh rò rỉ bộ nhớ
    _messagesSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchConversations() async {
    try {
      final result = await _chatService.getConversations();
      result.sort((a, b) => (b.lastMessageCreatedAt ?? DateTime(2000))
          .compareTo(a.lastMessageCreatedAt ?? DateTime(2000)));
      conversations.assignAll(result);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách trò chuyện');
    } finally {
      if (isLoading.isTrue) {
        isLoading.value = false;
      }
    }
  }

  void navigateToChatDetail(Conversation conversation) {
    Get.toNamed(Routes.CHAT_DETAIL, arguments: conversation);
  }
}
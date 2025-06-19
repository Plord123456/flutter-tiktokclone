// lib/app/modules/chat/chat_list/controllers/chat_list_controller.dart

import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';
import 'package:tiktok_clone/services/chat_service.dart';

class ChatListController extends GetxController {
  final ChatService _chatService = Get.find();

  final isLoading = true.obs;
  final conversations = <Conversation>[].obs;

  @override
  void onReady() {
    super.onReady();
    // Tự động tải danh sách trò chuyện khi màn hình sẵn sàng
    fetchConversations();
  }

  // Hàm để lấy dữ liệu từ service
  Future<void> fetchConversations() async {
    try {
      isLoading(true);
      final result = await _chatService.getConversations();
      // Sắp xếp để cuộc trò chuyện mới nhất lên đầu
      result.sort((a, b) => (b.lastMessageCreatedAt ?? DateTime(2000))
          .compareTo(a.lastMessageCreatedAt ?? DateTime(2000)));
      conversations.assignAll(result);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách trò chuyện');
    } finally {
      isLoading(false);
    }
  }

  // Hàm để điều hướng khi người dùng nhấn vào một cuộc trò chuyện
  void navigateToChatDetail(Conversation conversation) {
    Get.toNamed(Routes.CHAT_DETAIL, arguments: conversation);
  }
}
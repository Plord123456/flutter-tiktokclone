import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/services/chat_service.dart';

class ChatListController extends GetxController {
  final ChatService _chatService = Get.find();

  var conversations = <Conversation>[].obs;
  var isLoading = true.obs;

  // V MỚI: Thêm RefreshController
  final RefreshController refreshController = RefreshController(initialRefresh: false);

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
  }

  // V MỚI: Hàm để lấy dữ liệu
  Future<void> fetchConversations() async {
    isLoading.value = true;
    try {
      final result = await _chatService.getConversations();
      conversations.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  // V MỚI: Hàm xử lý khi người dùng kéo để làm mới
  void onRefresh() async {
    await fetchConversations();
    refreshController.refreshCompleted();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }
}

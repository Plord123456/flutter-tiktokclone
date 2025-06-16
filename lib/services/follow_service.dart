import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FollowService
///
/// Service tập trung, chịu trách nhiệm cho tất cả các logic liên quan đến
/// việc theo dõi (follow) và bỏ theo dõi (unfollow) người dùng.
class FollowService extends GetxService {
  // --- SỬA LỖI 1: Đưa các biến vào trong class ---
  // Giúp code được đóng gói tốt hơn và tránh biến toàn cục.
  final supabase = Supabase.instance.client;

  /// Lấy ID của người dùng đang đăng nhập.
  String? get currentUserId => supabase.auth.currentUser?.id;

  // --- SỬA LỖI 2: Xóa khai báo bị trùng lặp ---
  // Giữ lại một khai báo duy nhất và đúng cú pháp cho RxSet.
  final RxSet<String> followedUserIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Khi service được khởi tạo, gọi hàm để lấy danh sách follow ban đầu.
    _fetchInitialFollows();
  }

  /// Lấy danh sách những người mình đang follow từ database khi khởi động.
  Future<void> _fetchInitialFollows() async {
    if (currentUserId == null) return;
    try {
      final response = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId!);

      if (response.isNotEmpty) {
        // Chuyển đổi danh sách kết quả thành một Set các ID.
        final ids = response.map<String>((item) => item['following_id']).toSet();
        followedUserIds.assignAll(ids);
      }
    } catch (e) {
      print('Error fetching initial follows: $e');
    }
  }

  /// Hàm chính để xử lý việc follow hoặc unfollow.
  /// Nó sẽ tự kiểm tra trạng thái hiện tại để quyết định hành động phù hợp.
  Future<void> toggleFollow(String userId) async {
    if (followedUserIds.contains(userId)) {
      await unfollowUser(userId);
    } else {
      await followUser(userId);
    }
  }

  /// Theo dõi một người dùng.
  Future<void> followUser(String userIdToFollow) async {
    if (currentUserId == null || userIdToFollow == currentUserId) return;

    // 1. Cập nhật UI trước (Optimistic Update)
    followedUserIds.add(userIdToFollow);

    try {
      // 2. Gọi API để insert dữ liệu vào database
      await supabase.from('follows').insert({
        'follower_id': currentUserId!,
        'following_id': userIdToFollow,
      });
    } catch (e) {
      // 3. Nếu có lỗi, khôi phục lại trạng thái UI
      followedUserIds.remove(userIdToFollow);
      Get.snackbar('Lỗi', 'Không thể theo dõi người dùng này.');
      print('Error following user: $e');
    }
  }

  /// Bỏ theo dõi một người dùng.
  Future<void> unfollowUser(String userIdToUnfollow) async {
    if (currentUserId == null) return;

    // 1. Cập nhật UI trước (Optimistic Update)
    followedUserIds.remove(userIdToUnfollow);

    try {
      // 2. Gọi API để xóa dữ liệu khỏi database
      await supabase.from('follows').delete().match({
        'follower_id': currentUserId!,
        'following_id': userIdToUnfollow,
      });
    } catch (e) {
      // 3. Nếu có lỗi, khôi phục lại trạng thái UI
      followedUserIds.add(userIdToUnfollow);
      Get.snackbar('Lỗi', 'Không thể bỏ theo dõi người dùng này.');
      print('Error unfollowing user: $e');
    }
  }

  /// Hàm tiện ích để kiểm tra xem có đang follow một user cụ thể hay không.
  bool isFollowing(String userId) {
    return followedUserIds.contains(userId);
  }
}

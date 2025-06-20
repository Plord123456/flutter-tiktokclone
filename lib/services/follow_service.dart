import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService extends GetxService {
  final RxBool isLoading = false.obs;
  final supabase = Supabase.instance.client;

  /// Lấy ID của người dùng đang đăng nhập.
  String? get currentUserId => supabase.auth.currentUser?.id;

  // --- SỬA LỖI 2: Xóa khai báo bị trùng lặp ---
  // Giữ lại một khai báo duy nhất và đúng cú pháp cho RxSet.
  final RxSet<String> followedUserIds = <String>{}.obs;
  void _listenToFollowChanges() {
    supabase
        .from('follows')
        .stream(primaryKey: ['follower_id', 'following_id']) // Giả sử đây là PK
        .eq('follower_id', currentUserId!)
        .listen((List<Map<String, dynamic>> data) {
      final newIds = data.map<String>((item) => item['following_id']).toSet();
      followedUserIds.assignAll(newIds);
    });
  }
  @override
  void onInit() {
    super.onInit();
    _fetchInitialFollows();
    _listenToFollowChanges();
  }
  Future<void> _fetchInitialFollows() async {
    if (currentUserId == null) return;
    try {
      final response = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId!);
      if (response.isNotEmpty) {
        final ids = response.map<String>((item) => item['following_id']).toSet();
        followedUserIds.assignAll(ids);
      }
    } catch (e) {
      print('Error fetching initial follows: $e');
    }
  }
  void clearStateOnLogout() {
    followedUserIds.clear();
  }
  Future<void> toggleFollow(String userId) async {
    if (isLoading.isTrue) return; // Không cho thực hiện nếu đang có tác vụ khác

    isLoading.value = true; // Bắt đầu xử lý
    try {
      if (followedUserIds.contains(userId)) {
        await unfollowUser(userId);
      } else {
        await followUser(userId);
      }
    } finally {
      isLoading.value = false; // Luôn đảm bảo trả về false sau khi xong
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

  bool isFollowing(String userId) {
    return followedUserIds.contains(userId);
  }
}

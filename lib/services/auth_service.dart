import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';

class AuthService extends GetxService {
  final supabase = Supabase.instance.client;

  /// ✅ NGUỒN DỮ LIỆU TRUNG TÂM CHO PROFILE
  /// Mọi nơi trong app sẽ lắng nghe biến này để lấy thông tin user.
  final Rxn<Profile> userProfile = Rxn<Profile>();

  // Getter tiện ích
  bool get isLoggedIn => supabase.auth.currentUser != null;
  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();

    // Ngay khi service khởi tạo, kiểm tra và tải profile nếu đã đăng nhập
    if (isLoggedIn) {
      _fetchUserProfile();
    }

    // Lắng nghe các thay đổi về trạng thái đăng nhập (login/logout)
    supabase.auth.onAuthStateChange.listen((data) {
      final User? user = data.session?.user;
      if (user != null) {
        // Nếu user đăng nhập, fetch profile của họ
        print('User is logged in. Fetching profile...');
        _fetchUserProfile();
      } else {
        // Nếu user đăng xuất, xóa profile
        print('User is logged out. Clearing profile.');
        userProfile.value = null;
      }
    });
  }

  /// Hàm private để tải profile từ DB và cập nhật state
  Future<void> _fetchUserProfile() async {
    if (currentUserId.isEmpty) return;
    try {
      final response = await supabase
          .from('profiles')
          .select() // Có thể thêm các count() vào đây nếu cần
          .eq('id', currentUserId)
          .single();
      userProfile.value = Profile.fromJson(response);
    } catch (e) {
      print("Lỗi khi fetch user profile trong AuthService: $e");
      userProfile.value = null;
    }
  }

  /// ✅ Hàm này được gọi từ màn hình Edit Profile sau khi cập nhật thành công
  void updateLocalProfile({required String newUsername, required String newFullName}) {
    if (userProfile.value != null) {
      // Cập nhật giá trị trong service
      userProfile.value!.username.value = newUsername;
      userProfile.value!.fullName.value = newFullName;
      // Dòng này không thực sự cần thiết nếu các widget dùng Obx,
      // nhưng có thể hữu ích trong một số trường hợp phức tạp.
      // userProfile.refresh(); 
      Get.snackbar('Thành công', 'Thông tin đã được cập nhật cục bộ!');
    }
  }

  // --- CÁC HÀM XÁC THỰC (giữ nguyên logic của bạn vì nó đã tốt) ---

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: "1081669241506-3c8unofrb9ejr7a0tj5d4tvhst1mvf9d.apps.googleusercontent.com",
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Không lấy được token từ Google.';
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // onAuthStateChange sẽ tự động fetch profile, chúng ta chỉ cần chuyển hướng
      Get.offAllNamed(Routes.LAYOUT);
      Get.snackbar("Thành Công", "Đăng nhập với Google thành công!");

    } catch (e) {
      if (kDebugMode) print('Lỗi đăng nhập Google: $e');
      Get.snackbar('Lỗi Đăng Nhập', 'Đã có lỗi xảy ra.');
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await supabase.auth.signOut();
      // onAuthStateChange sẽ tự động xóa profile, chúng ta chỉ cần chuyển hướng
      Get.offAllNamed(Routes.LOGIN); // Chuyển về trang đăng nhập
    } catch (e) {
      Get.snackbar('Lỗi Đăng Xuất', e.toString());
    }
  }
}
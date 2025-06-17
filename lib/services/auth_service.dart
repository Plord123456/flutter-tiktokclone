import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';

class AuthService extends GetxService {
  final supabase = Supabase.instance.client;

  /// ✅ NGUỒN DỮ LIỆU TRUNG TÂM CHO PROFILE
  final Rxn<Profile> userProfile = Rxn<Profile>();

  // Getter tiện ích
  bool get isLoggedIn => supabase.auth.currentUser != null;
  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();

    if (isLoggedIn) {
      _fetchUserProfile();
    }

    supabase.auth.onAuthStateChange.listen((data) {
      final User? user = data.session?.user;
      if (user != null) {
        _fetchUserProfile();
      } else {
        userProfile.value = null;
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    if (currentUserId.isEmpty) return;
    try {
      final response = await supabase
          .from('profiles')
          .select('*, post_count:videos(count)') // Có thể thêm các count khác nếu cần
          .eq('id', currentUserId)
          .single();
      userProfile.value = Profile.fromJson(response);
    } catch (e) {
      print("AuthService Error fetching profile: $e");
      userProfile.value = null;
    }
  }

  void updateLocalProfile({required String newUsername, required String newFullName, String? newAvatarUrl}) {
    if (userProfile.value != null) {
      userProfile.value!.username.value = newUsername;
      userProfile.value!.fullName.value = newFullName;
      if (newAvatarUrl != null) {
        userProfile.value!.avatarUrl.value = newAvatarUrl;
      }
      Get.snackbar('Thành công', 'Thông tin đã được cập nhật!');
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
      Get.offAllNamed(Routes.LOGIN); // Chuyển về trang đăng nhập
    } catch (e) {
      Get.snackbar('Lỗi Đăng Xuất', e.toString());
    }
  }
}
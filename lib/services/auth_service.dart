import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';

class AuthService extends GetxService {
  final supabase = Supabase.instance.client;
  final Rxn<Profile> userProfile = Rxn<Profile>();
  final RxBool isFetching = false.obs;

  bool get isLoggedIn => supabase.auth.currentUser != null;
  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    _setupAuthListener();
    if (isLoggedIn) {
      fetchUserProfile();
    }
  }
  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;
      if (event == AuthChangeEvent.signedIn && user != null) {
        fetchUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        userProfile.value = null;
      }
    });
  }

  // Hàm này chỉ fetch profile của người dùng hiện tại
  Future<void> fetchUserProfile() async {
    if (currentUserId.isEmpty || isFetching.value) return;

    isFetching.value = true;
    try {
      print("AuthService: Fetching profile for user: $currentUserId");
      final response = await supabase
          .from('profiles')
          .select('*') // Lấy tất cả thông tin profile
          .eq('id', currentUserId)
          .single();

      userProfile.value = Profile.fromJson(response, currentUserId: currentUserId);

    } catch (e) {
      print("AuthService Error fetching profile: $e");
      userProfile.value = null;
    } finally {
      isFetching.value = false;
    }
  }


  Future<void> updateUserProfile({
    required String newUsername,
    required String newFullName,
    String? newAvatarUrl,
    String? newDateOfBirth,
  }) async {
    if (currentUserId.isEmpty) {
      Get.snackbar('Lỗi', 'Không tìm thấy người dùng.');
      return;
    }

    isFetching.value = true;
    try {
      final updates = {
        'username': newUsername,
        'full_name': newFullName,
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      };

      await supabase.from('profiles').update(updates).eq('id', currentUserId);

      // 2. Cập nhật dữ liệu cục bộ trong chính AuthService
      if (userProfile.value != null) {
        userProfile.value!.updateProfile(
          newUsername: newUsername,
          newFullName: newFullName,
          newAvatarUrl: newAvatarUrl,
        );
        userProfile.refresh();
      }
      Get.snackbar('Thành công', 'Thông tin cá nhân đã được cập nhật.');
    } catch (e) {
      print('Error updating profile: $e');
      Get.snackbar('Lỗi', 'Cập nhật thông tin thất bại.');
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: "1081669241506-3c8unofrb9ejr7a0tj5d4tvhst1mvf9d.apps.googleusercontent.com",
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      // ✅ Ném ra lỗi để LoginController có thể bắt được
      throw 'Không lấy được token từ Google.';
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    Get.offAllNamed(Routes.LAYOUT);
    Get.snackbar("Thành Công", "Đăng nhập với Google thành công!");
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await supabase.auth.signOut();

      Get.offAllNamed(Routes.LOGIN);
      Get.snackbar("Đã đăng xuất", "Bạn đã đăng xuất thành công.");
    } catch (e) {
      Get.snackbar("Lỗi Đăng Xuất", "Đã có lỗi xảy ra: ${e.toString()}");
    }
  }
}
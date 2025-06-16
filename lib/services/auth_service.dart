
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import thư viện
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart'; // Import để sử dụng Routes

class AuthService extends GetxService {
  final supabase = Supabase.instance.client;
  final _rxUser = Rx<User?>(null);

  User? get currentUser => _rxUser.value;
  Stream<User?> get rxCurrentUser => _rxUser.stream;

  @override
  void onInit() {
    super.onInit();
    _rxUser.value = supabase.auth.currentUser;
    supabase.auth.onAuthStateChange.listen((data) {
      _rxUser.value = data.session?.user;
    });
  }

  Future<void> loginWithGoogle() async {
    try {

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: "1081669241506-3c8unofrb9ejr7a0tj5d4tvhst1mvf9d.apps.googleusercontent.com",
        clientId: "1081669241506-lldmublsqggpilabs7tg3kfsjvgej4oi.apps.googleusercontent.com",
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      // 3. Lấy thông tin xác thực (idToken, accessToken)
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'Không lấy được Access Token từ Google.';
      }
      if (idToken == null) {
        throw 'Không lấy được ID Token từ Google.';
      }

      // 4. Dùng id_token để đăng nhập vào Supabase
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 5. Đăng nhập thành công, chuyển hướng và thông báo
      // Việc lắng nghe onAuthStateChange sẽ tự động cập nhật trạng thái user
      Get.offAllNamed(Routes.LAYOUT);
      Get.snackbar("Thành Công", "Đăng nhập với Google thành công!");

    } catch (e) {
      if (kDebugMode) {
        print("===============================");
        print('Lỗi đăng nhập Google: $e');
      }
      Get.snackbar('Lỗi Đăng Nhập', 'Đã có lỗi xảy ra: $e');
    }
  }

  /// Xử lý đăng xuất
  Future<void> signOut() async {
    try {
      // Đăng xuất khỏi cả Google và Supabase để đảm bảo sạch sẽ
      await GoogleSignIn().signOut();
      await supabase.auth.signOut();
    } catch (e) {
      Get.snackbar('Lỗi Đăng Xuất', e.toString());
    }
  }
}

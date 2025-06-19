import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modules/UserFeed/bindings/user_feed_binding.dart';
import '../modules/UserFeed/views/user_feed_view.dart';
import '../modules/chat_detail/bindings/chat_detail_binding.dart';
import '../modules/chat_detail/views/chat_detail_view.dart';
import '../modules/chat_list/bindings/chat_list_binding.dart';
import '../modules/chat_list/views/chat_list_view.dart';
import '../modules/confirm_upload/views/confirm_upload_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/layout/bindings/layout_binding.dart';
import '../modules/layout/views/layout_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/edit_profile_view.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/video_user/bindings/video_user_binding.dart';
import '../modules/video_user/views/video_user_view.dart';
import 'app_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static final INITIAL =
      Supabase.instance.client.auth.currentSession?.user != null
          ? Routes.LAYOUT
          : Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LAYOUT,
      page: () => const LayoutView(),
      binding: LayoutBinding(),
      middlewares: [AuthMiddleware()], // Áp dụng middleware cho trang chủ
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
      GetPage(
        name: '/user',
        page: () => const VideoUserView(profileId:,),
        binding: VideoUserBinding(), // Đảm bảo có binding để inject controller
      ),
    GetPage(
      name: _Paths.USER_FEED,
      page: () => const UserFeedView(),
      binding: UserFeedBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_PROFILE, // Sử dụng Routes.EDIT_PROFILE
      page: () => const EditProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_LIST,
      page: () => const ChatListView(),
      binding: ChatListBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_DETAIL,
      page: () => const ChatDetailView(),
      binding: ChatDetailBinding(),
    ),
  ];
}

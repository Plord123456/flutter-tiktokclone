import 'package:get/get.dart';
import 'package:tiktok_clone/app/modules/UserFeed/bindings/user_feed_binding.dart';
import 'package:tiktok_clone/app/modules/UserFeed/views/user_feed_view.dart';
import 'package:tiktok_clone/app/modules/chat_detail/bindings/chat_detail_binding.dart';
import 'package:tiktok_clone/app/modules/chat_detail/views/chat_detail_view.dart';
import 'package:tiktok_clone/app/modules/chat_list/bindings/chat_list_binding.dart';
import 'package:tiktok_clone/app/modules/chat_list/views/chat_list_view.dart';
import 'package:tiktok_clone/app/modules/home/bindings/home_binding.dart';
import 'package:tiktok_clone/app/modules/home/views/home_view.dart';
import 'package:tiktok_clone/app/modules/layout/bindings/layout_binding.dart';
import 'package:tiktok_clone/app/modules/layout/views/layout_view.dart';
import 'package:tiktok_clone/app/modules/login/bindings/login_binding.dart';
import 'package:tiktok_clone/app/modules/login/views/login_view.dart';
import 'package:tiktok_clone/app/modules/profile/bindings/profile_binding.dart';
import 'package:tiktok_clone/app/modules/profile/views/profile_view.dart';
import 'package:tiktok_clone/app/modules/video_user/bindings/video_user_binding.dart';
import 'package:tiktok_clone/app/modules/video_user/views/video_user_view.dart';
import 'app_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  // INITIAL route logic remains the same
  static const INITIAL = Routes.LAYOUT;

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
      middlewares: [AuthMiddleware()],
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
      name: _Paths.USER_FEED,
      page: () => const UserFeedView(),
      binding: UserFeedBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_LIST,
      page: () => const ChatListView(),
      binding: ChatListBinding(),
    ),
    GetPage(
      name: _Paths.USER_PROFILE,

      page: () => const VideoUserView(),
      binding: VideoUserBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_DETAIL,
      page: () => const ChatDetailView(),
      binding: ChatDetailBinding(),
    ),
  ];
}

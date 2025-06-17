import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart'; // Import AuthService
import 'app_pages.dart';


class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {

    final authService = Get.find<AuthService>();

    final bool isAuthenticated = authService.currentUserId != null;

    const loginRoute = Routes.LOGIN;

    if (isAuthenticated) {
      if (route == loginRoute) {
        return const RouteSettings(name: Routes.LAYOUT); // hoặc Routes.HOME
      }
      return null;
    }
    else {
      if (route != loginRoute) {
        return const RouteSettings(name: Routes.LOGIN);
      }
      return null;
    }
  }
}

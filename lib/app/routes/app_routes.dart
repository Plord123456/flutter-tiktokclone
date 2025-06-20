part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const LAYOUT = _Paths.LAYOUT;
  static const LOGIN = _Paths.LOGIN;
  static const PROFILE = _Paths.PROFILE;
  static const UPLOAD_VIDEO = _Paths.UPLOAD_VIDEO; // ✅ SỬA CHÍNH TẢ
  static const CONFIRM_UPLOAD = _Paths.CONFIRM_UPLOAD;
  static const USER_FEED = _Paths.USER_FEED;
  static const EDIT_PROFILE = _Paths.EDIT_PROFILE;
  static const CHAT_LIST = _Paths.CHAT_LIST;
  static const USER_PROFILE = _Paths.USER_PROFILE; // ✅ Phải có dòng này
  static const CHAT_DETAIL = _Paths.CHAT_DETAIL;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const LAYOUT = '/layout';
  static const LOGIN = '/login';
  static const PROFILE = '/profile';
  static const USER_PROFILE = '/user/:profileId';
  static const UPLOAD_VIDEO = '/upload-video'; // ✅ SỬA CHÍNH TẢ
  static const CONFIRM_UPLOAD = '/confirm-upload';
  static const EDIT_PROFILE = '/profile/edit';
  static const USER_FEED = '/user-feed';
  static const CHAT_LIST = '/chat-list';
  static const CHAT_DETAIL = '/chat-detail';
}

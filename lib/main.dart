
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

import 'package:tiktok_clone/resources/theme.dart';
import 'package:tiktok_clone/utilities/theme_util.dart';
import 'app/data/models/theme_model.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';
import 'initial_binding.dart';

void main() async {
  // Đảm bảo các thành phần Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();
  // --- SỬA LỖI: Lấy kết quả từ Future.wait đúng cách ---
  // Chạy các tác vụ khởi tạo song song và nhận kết quả là một List.
  final results = await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Supabase.initialize(
      url: 'https://rehdwfkhvkxaiibzidwx.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlaGR3Zmtodmt4YWlpYnppZHd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMjUwNDIsImV4cCI6MjA2NDgwMTA0Mn0.4AGphHKYmKGsQnUDhppVR76tXT-sQbhD35XKMMJLY-M',
    ),
    SharedPreferences.getInstance(),
  ]);

  // Lấy đối tượng SharedPreferences từ danh sách kết quả ở vị trí thứ 3 (index 2)
  // và ép kiểu nó một cách tường minh.
  final SharedPreferences prefs = results[2] as SharedPreferences;
  bool isDarkTheme = prefs.getBool('isDarkTheme') ?? true;

  // Đặt chế độ UI cho toàn màn hình
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    // Sử dụng Provider để quản lý theme
    ChangeNotifierProvider<ThemeModel>(
      create: (_) => ThemeModel(isDarkTheme),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(builder: (context, themeModel, child) {
      // Tạo theme dựa trên trạng thái hiện tại
      TextTheme textTheme = createTextTheme(context, 'Lexend', "Lexend");
      MaterialTheme theme = MaterialTheme(textTheme);

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tiktok Clone',
        theme: theme.light(),
        darkTheme: theme.dark(),
        themeMode: themeModel.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
        initialBinding: InitialBinding(),
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      );
    });
  }
}
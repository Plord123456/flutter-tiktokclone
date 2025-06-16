  import 'package:flutter/material.dart';

  class ThemeModel extends ChangeNotifier {
    bool _isDarkTheme = false;

    ThemeModel(bool isDarkTheme) {
      _isDarkTheme = isDarkTheme;
    }

    bool get isDarkTheme => _isDarkTheme;

    void toggleTheme(bool isDarkTheme) {
      _isDarkTheme = isDarkTheme;
      notifyListeners();
    }
  }
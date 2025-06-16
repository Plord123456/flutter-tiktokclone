import 'package:get/get.dart';
class Tag {
  final int id;
  final String name;
  final RxBool isFavorited;

  Tag({
    required this.id,
    required this.name,
    required bool initialIsFavorited,
  }) : isFavorited = initialIsFavorited.obs;

  factory Tag.fromJson(Map<String, dynamic> json) {
    try {
      return Tag(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        initialIsFavorited: json['is_favorited'] as bool? ?? false,
      );
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể phân tích dữ liệu tag: ${e.toString()}');
      return Tag(id: 0, name: 'Unknown Tag', initialIsFavorited: false);
    }
  }
}
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tiktok_clone/app/modules/confirm_upload/views/confirm_upload_view.dart';

class MediaService extends GetxService {
  final ImagePicker _picker = ImagePicker();
  
  Future<void> pickAndNavigateToConfirm() async {
    // 1. Gọi hàm chọn và sao chép video đã có sẵn
    final safeVideoFile = await pickAndCopyVideoToSafeDirectory();

    // 2. Nếu người dùng chọn file thành công (không hủy giữa chừng)
    if (safeVideoFile != null) {
      // 3. Điều hướng đến màn hình xác nhận và truyền file đi
      Get.to(() => ConfirmUploadView(videoFile: safeVideoFile));
    }
    // Nếu không, không làm gì cả. Người dùng đã hủy thao tác.
  }



  Future<File?> pickAndCopyVideoToSafeDirectory() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video == null) {
        // Người dùng đã hủy việc chọn video
        return null;
      }

      // Lấy đường dẫn đến thư mục an toàn của ứng dụng
      final appDir = await getApplicationDocumentsDirectory();
      // Tạo một tên file mới, duy nhất để tránh trùng lặp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(video.path)}';
      final savedVideo = await File(video.path).copy('${appDir.path}/$fileName');

      return savedVideo;

    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video: ${e.toString()}');
      return null;
    }
  }
}
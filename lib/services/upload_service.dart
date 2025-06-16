
import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../app/data/models/upload_result_model.dart';


class MediaService extends GetxService {

  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Mở thư viện, cho người dùng chọn video và copy nó vào một thư mục an toàn của ứng dụng.
  /// Trả về một File object trỏ đến file đã được copy.
  Future<File?> pickAndCopyVideoToSafeDirectory() async {
    try   {
      final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (videoFile == null) return null; // Người dùng hủy chọn file

      final cachedFile = File(videoFile.path);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(videoFile.path)}';
      final safePath = p.join(appDir.path, fileName);

      final safeFile = await cachedFile.copy(safePath);
      print('File đã được copy vào nơi an toàn: ${safeFile.path}');
      return safeFile;
    } catch (e) {
      Get.snackbar('Lỗi Chọn File', 'Không thể chọn video: ${e.toString()}');
      return null;
    }
  }

  /// Hàm chính để upload: Nén, tạo thumbnail, upload và trả về kết quả.
  Future<UploadResult?> uploadMedia(File rawVideoFile) async {
    if (_userId == null) {
      print("DEBUG LỖI: User ID là null, không thể upload.");
      throw Exception('Lỗi nghiêm trọng: Người dùng chưa đăng nhập!');
    }
    print("DEBUG: Bắt đầu quá trình uploadMedia cho user: $_userId");

    File? compressedVideo;
    File? thumbnail;

    try {
      // 1. Nén video
      print("DEBUG: Bắt đầu nén video...");
      compressedVideo = await _compressVideo(rawVideoFile);
      final fileSizeInMB = await compressedVideo.length() / (1024 * 1024);
      print('DEBUG: Nén video thành công. Kích thước: ${fileSizeInMB.toStringAsFixed(2)} MB. Path: ${compressedVideo.path}');

      // 2. Tạo thumbnail
      print("DEBUG: Bắt đầu tạo thumbnail...");
      thumbnail = await _generateThumbnail(compressedVideo);
      print('DEBUG: Tạo thumbnail thành công. Path: ${thumbnail.path}');

      // 3. Upload song song
      print('DEBUG: Bắt đầu upload song song...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoUploadTask = _uploadFile(compressedVideo, 'videos', '$timestamp');
      final thumbnailUploadTask = _uploadFile(thumbnail, 'thumbnails', '$timestamp');

      final results = await Future.wait([videoUploadTask, thumbnailUploadTask]);
      final videoUrl = results[0];
      final thumbnailUrl = results[1];
      print('DEBUG: Upload song song thành công!');

      return UploadResult(videoUrl: videoUrl, thumbnailUrl: thumbnailUrl);

    } catch (e) {
      print("DEBUG LỖI: Gặp lỗi trong hàm uploadMedia. Chi tiết: $e");
      Get.snackbar('Lỗi Upload', 'Quá trình đăng tải đã thất bại. Vui lòng xem console.');
      return null;
    } finally {
      // 4. Dọn dẹp file
      print('DEBUG: Bắt đầu dọn dẹp file tạm...');
      if (await rawVideoFile.exists()) await rawVideoFile.delete();
      if (compressedVideo != null && await compressedVideo.exists()) await compressedVideo.delete();
      if (thumbnail != null && await thumbnail.exists()) await thumbnail.delete();
      print('DEBUG: Dọn dẹp file tạm hoàn tất.');
    }
  }


  // === CÁC HÀM HELPER PRIVATE ===

  Future<File> _compressVideo(File rawVideoFile) async {
    try {
      final info = await VideoCompress.compressVideo(
        rawVideoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      if (info?.file == null) throw Exception('Nén video trả về null.');
      return info!.file!;
    } catch(e) {
      print("DEBUG LỖI: Lỗi xảy ra trong _compressVideo: $e");
      rethrow; // Ném lại lỗi để khối catch bên trên bắt được
    }
  }


  Future<File> _generateThumbnail(File videoFile) async {
    try {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 360,
        quality: 75,
      );
      if (thumbPath == null) throw Exception('Tạo thumbnail trả về null.');
      return File(thumbPath);
    } catch(e) {
      print("DEBUG LỖI: Lỗi xảy ra trong _generateThumbnail: $e");
      rethrow;
    }
  }

  Future<String> _uploadFile(File file, String bucket, String timestamp) async {
    final fileExtension = p.extension(file.path);
    final filePath = '$_userId/$timestamp$fileExtension';
    print("DEBUG: Đang chuẩn bị upload file lên bucket '$bucket' tại đường dẫn: $filePath");
    try {
      await _supabase.storage.from(bucket).upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      print("DEBUG: Upload file '$filePath' lên bucket '$bucket' THÀNH CÔNG.");
      return _supabase.storage.from(bucket).getPublicUrl(filePath);
    } on StorageException catch (e) {
      print("DEBUG LỖI STORAGE: Lỗi khi upload file lên bucket '$bucket'.");
      print("DEBUG LỖI STORAGE: Message: ${e.message}");
      print("DEBUG LỖI STORAGE: StatusCode: ${e.statusCode}");
      print("DEBUG LỖI STORAGE: Error: ${e.error}");
      rethrow;
    } catch (e) {
      print("DEBUG LỖI: Lỗi không xác định trong _uploadFile: $e");
      rethrow;
    }
  }
}
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../app/data/models/upload_result_model.dart';


class MediaService extends GetxService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;


  Future<File?> pickAndCopyVideoToSafeDirectory() async {
    try {
      final XFile? videoFile =
      await _picker.pickVideo(source: ImageSource.gallery);
      if (videoFile == null) return null; // Người dùng hủy chọn file

      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(videoFile.path)}';
      final safePath = p.join(appDir.path, fileName);
      final safeFile = await File(videoFile.path).copy(safePath);

      print('File đã được copy vào nơi an toàn: ${safeFile.path}');
      return safeFile;
    } catch (e) {
      Get.snackbar('Lỗi Chọn File', 'Không thể chọn video: ${e.toString()}');
      return null;
    }
  }

  Future<UploadResult?> uploadMedia(File rawVideoFile,
      {required Function(String status) onProgress}) async {
    if (_userId == null) {
      throw Exception('Lỗi nghiêm trọng: Người dùng chưa đăng nhập!');
    }

    File? processedVideo;
    File? thumbnail;

    try {
      // 1. Tối ưu hóa video bằng ffmpeg
      onProgress('Đang xử lý video...');
      processedVideo = await _processVideoWithFFmpeg(rawVideoFile);

      // 2. Tạo thumbnail từ video đã xử lý
      onProgress('Đang tạo ảnh đại diện...');
      thumbnail = await _generateThumbnail(processedVideo);

      // 3. Upload song song video và thumbnail
      onProgress('Đang tải lên...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoUploadTask =
      _uploadFile(processedVideo, 'videos', '$timestamp');
      final thumbnailUploadTask =
      _uploadFile(thumbnail, 'thumbnails', '$timestamp');

      // Chờ cả hai hoàn thành
      final results = await Future.wait([videoUploadTask, thumbnailUploadTask]);
      final videoUrl = results[0];
      final thumbnailUrl = results[1];

      onProgress('Hoàn tất!');
      return UploadResult(videoUrl: videoUrl, thumbnailUrl: thumbnailUrl);
    } catch (e) {
      print("Lỗi trong hàm uploadMedia: $e");
      // Ném lại lỗi để controller có thể xử lý và hiển thị cho người dùng
      rethrow;
    } finally {
      // 4. Dọn dẹp file tạm để tiết kiệm dung lượng
      print('Bắt đầu dọn dẹp file tạm...');
      if (await rawVideoFile.exists()) await rawVideoFile.delete();
      if (processedVideo != null && await processedVideo.exists()) {
        await processedVideo.delete();
      }
      if (thumbnail != null && await thumbnail.exists()) {
        await thumbnail.delete();
      }
      print('Dọn dẹp file tạm hoàn tất.');
    }
  }

  // === CÁC HÀM HELPER PRIVATE ===

  /// Sử dụng FFmpeg để nén và tối ưu hóa video cho streaming.
  Future<File> _processVideoWithFFmpeg(File rawVideoFile) async {
    final tempDir = await getTemporaryDirectory();
    final outputFileName =
        'processed_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final outputFile = File('${tempDir.path}/$outputFileName');

    // Lệnh ffmpeg:
    // -i: input file
    // -c:v libx264: codec video phổ biến, tương thích rộng
    // -crf 23: mức chất lượng (Constant Rate Factor, 18-28 là khoảng tốt)
    // -preset veryfast: cân bằng giữa tốc độ nén và dung lượng
    // -movflags +faststart: TỐI QUAN TRỌNG - đưa metadata lên đầu file để streaming
    // -y: ghi đè file output nếu đã tồn tại
    final command =
        '-i "${rawVideoFile.path}" -c:v libx264 -crf 23 -preset veryfast -movflags +faststart -y "${outputFile.path}"';

    print('Đang thực thi FFmpeg: $command');
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final originalSize = rawVideoFile.lengthSync() / (1024 * 1024);
      final newSize = outputFile.lengthSync() / (1024 * 1024);
      print(
          'FFmpeg xử lý thành công. Size gốc: ${originalSize.toStringAsFixed(2)}MB. Size mới: ${newSize.toStringAsFixed(2)}MB');
      return outputFile;
    } else {
      final logs = await session.getAllLogsAsString();
      print('FFmpeg xử lý thất bại. Lỗi: $logs');
      // Nếu thất bại, vẫn trả về file gốc để không làm gián đoạn quá trình upload
      return rawVideoFile;
    }
  }

  Future<File> _generateThumbnail(File videoFile) async {
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG, // JPEG nhẹ hơn PNG cho thumbnail
      maxWidth: 480, // Tăng chất lượng thumbnail một chút
      quality: 80,
    );
    if (thumbPath == null) throw Exception('Tạo thumbnail trả về null.');
    return File(thumbPath);
  }

  Future<String> _uploadFile(
      File file, String bucket, String timestamp) async {
    final fileExtension = p.extension(file.path);
    final filePath = '$_userId/$timestamp$fileExtension';

    await _supabase.storage.from(bucket).upload(
      filePath,
      file,
      fileOptions: const FileOptions(
          cacheControl: '3600', upsert: false), // Cache trong 1 giờ
    );

    return _supabase.storage.from(bucket).getPublicUrl(filePath);
  }
}

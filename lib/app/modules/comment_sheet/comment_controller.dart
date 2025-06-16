import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/comments_model.dart';

class CommentController extends GetxController {
  final String videoId;
  CommentController({required this.videoId});

  final SupabaseClient supabase = Supabase.instance.client;
  final isLoading = true.obs;
  final isPostingComment = false.obs;
  final comments = <Comment>[].obs;
  final scrollController = ScrollController();
  final textController = TextEditingController();
  final Rx<Comment?> replyingTo = Rx<Comment?>(null);
  late final String? currentUserId;

  final String _commentSelectQuery =
      'id, content, created_at, user_id, video_id, parent_comment_id, profiles!inner(username, avatar_url)';

  @override
  void onInit() {
    super.onInit();
    currentUserId = supabase.auth.currentUser?.id;
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      isLoading.value = true;
      if (currentUserId == null) return;

      // ✅ SỬA LỖI: Xóa bỏ phần truy vấn đến bảng "comment_likes" không tồn tại.
      final response = await supabase
          .from('comments')
          .select(_commentSelectQuery)
          .eq('video_id', videoId)
          .order('created_at', ascending: true);

      // Bây giờ, chúng ta sẽ map dữ liệu trực tiếp mà không cần xử lý "like".
      final allComments = response
          .map((json) => Comment.fromJson(json))
          .toList();

      final commentMap = {for (var c in allComments) c.id: c};
      final topLevelComments = <Comment>[];

      for (var comment in allComments) {
        final parentId = comment.parentCommentId?.toString();
        if (parentId != null && commentMap.containsKey(parentId)) {
          commentMap[parentId]!.replies.add(comment);
        } else {
          topLevelComments.add(comment);
        }
      }
      comments.assignAll(topLevelComments);

    } catch (e) {
      Get.snackbar('Lỗi tải dữ liệu', 'Không thể tải bình luận: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addComment() async {
    final text = textController.text.trim();
    if (text.isEmpty || currentUserId == null) return;

    isPostingComment.value = true;

    try {
      final parentIdValue = replyingTo.value?.id;
      final payload = {
        'content': text,
        'video_id': videoId,
        'user_id': currentUserId!,
        'parent_comment_id': parentIdValue != null ? int.tryParse(parentIdValue) : null,
      };

      final newCommentData = await supabase
          .from('comments')
          .insert(payload)
          .select(_commentSelectQuery)
          .single();

      final newComment = Comment.fromJson(newCommentData);
      _addCommentToList(newComment);
      textController.clear();
      replyingTo.value = null;

    } catch (e) {
      Get.snackbar('Lỗi', 'Gửi bình luận thất bại: ${e.toString()}');
    } finally {
      isPostingComment.value = false;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final commentIdAsInt = int.tryParse(commentId);
      if (commentIdAsInt == null) {
        Get.snackbar("Lỗi", "ID bình luận không hợp lệ.");
        return;
      }
      await supabase.from('comments').delete().eq('id', commentIdAsInt);
      if (_deleteCommentRecursive(commentId, comments)) {
        Get.back();
        Get.snackbar("Thành công", "Đã xóa bình luận.");
      }
    } catch(e) {
      Get.snackbar("Lỗi", "Không thể xóa bình luận này.");
    }
  }

  // ✅ SỬA LỖI: Hàm này sẽ được giữ lại nhưng không có logic bên trong.
  // Widget của bạn vẫn sẽ gọi nó, nhưng sẽ không có lỗi xảy ra.
  void toggleLike(String commentId) {
    // Tạm thời không làm gì cả để tránh lỗi.
    // Nếu muốn có chức năng này, bạn cần tạo bảng `comment_likes` trong DB.
    print("Chức năng thích bình luận đang được tạm tắt.");
  }


  // --- CÁC HÀM HELPER ---

  void _addCommentToList(Comment comment) {
    if (replyingTo.value != null) {
      final parent = comments.firstWhereOrNull((c) => c.id == replyingTo.value!.id);
      if (parent != null) {
        parent.replies.add(comment);
      }
    } else {
      comments.add(comment);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _deleteCommentRecursive(String id, RxList<Comment> commentList) {
    for (int i = 0; i < commentList.length; i++) {
      if (commentList[i].id == id) {
        commentList.removeAt(i);
        return true;
      }
      if (_deleteCommentRecursive(id, commentList[i].replies)) return true;
    }
    return false;
  }

  void startReply(Comment comment) {
    replyingTo.value = comment;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/comments_model.dart';
import '../home/controllers/home_controller.dart';

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

  // ✅ IMPROVEMENT: Khai báo biến state còn thiếu
  final RxSet<String> deletingCommentIds = <String>{}.obs;

  // ✅ IMPROVEMENT: Query hiệu quả hơn, gộp 2 API call thành 1
  final String _commentSelectQuery =
      '*, profiles!inner(username, avatar_url), comment_likes!left(user_id)';

  @override
  void onInit() {
    super.onInit();
    currentUserId = supabase.auth.currentUser?.id;
    fetchComments();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
  int get totalCommentCount {
    int count = 0;
    // Đếm các bình luận gốc
    for (var comment in comments) {
      // Mỗi bình luận gốc được tính là 1, cộng với số lượng trả lời của nó
      count += 1 + _countReplies(comment.replies);
    }
    return count;
  }

  /// Hàm đệ quy để đếm các trả lời con
  int _countReplies(List<Comment> replies) {
    int count = replies.length; // Đếm các trả lời ở cấp hiện tại
    for (var reply in replies) {
      // Cộng dồn số lượng trả lời của các cấp con
      count += _countReplies(reply.replies);
    }
    return count;
  }
  // ✅ REFACTOR: Tối ưu hóa hàm fetchComments
  Future<void> fetchComments({bool isRefresh = false}) async {
    if (!isRefresh) isLoading.value = true;

    try {
      if (currentUserId == null || currentUserId!.isEmpty) {
        isLoading.value = false;
        comments.clear();
        return;
      }

      final response = await supabase
          .from('comments')
          .select(_commentSelectQuery)
          .eq('video_id', videoId)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        comments.clear();
        return;
      }

      final allComments = response
          .map((json) => Comment.fromSupabase(json, currentUserId: currentUserId!))
          .toList();

      final commentMap = {for (var c in allComments) c.id: c};
      final topLevelComments = <Comment>[];

      for (var comment in allComments) {
        final parentId = comment.parentCommentId;
        if (parentId != null && commentMap.containsKey(parentId)) {
          commentMap[parentId]!.replies.add(comment);
        } else {
          topLevelComments.add(comment);
        }
      }

      topLevelComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      comments.assignAll(topLevelComments);
    } catch (e) {
      print('Fetch Comments Error: $e'); // Debug log
      Get.snackbar('Lỗi tải dữ liệu', 'Không thể tải bình luận: ${e.toString()}');
    } finally {
      if (!isRefresh) isLoading.value = false;
    }
  }
  // Trong file comment_controller.dart

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
        'parent_comment_id': parentIdValue,
      };

      final response = await supabase.from('comments').insert(payload).select(_commentSelectQuery).single();
      final newComment = Comment.fromSupabase(response, currentUserId: currentUserId!);

      // Cập nhật UI của comment sheet (code này của bạn đã đúng)
      if (parentIdValue != null) {
        final parentComment = _findCommentById(parentIdValue);
        if (parentComment != null) {
          parentComment.replies.insert(0, newComment); // Thêm vào đầu danh sách trả lời
        }
      } else {
        comments.insert(0, newComment);
      }

      // ✅ BƯỚC 1: ĐỒNG BỘ SỐ LƯỢNG VỚI HOMECONTROLLER
      // Kiểm tra xem HomeController có đang chạy không rồi mới tìm
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        // Tìm video tương ứng trong danh sách của HomeController
        final video = homeController.videoList.firstWhereOrNull((v) => v.id == videoId);
        if (video != null) {
          // Tăng số đếm comment của video đó lên
          video.commentCount.value++;
        }
      }

      textController.clear();
      cancelReply();
    } catch (e) {
      Get.snackbar('Lỗi', 'Gửi bình luận thất bại: ${e.toString()}');
    } finally {
      isPostingComment.value = false;
    }
  }
  // Trong file comment_controller.dart

  Future<void> deleteComment(String commentId) async {
    deletingCommentIds.add(commentId);

    final commentToDelete = _findCommentById(commentId);
    if (commentToDelete == null) {
      deletingCommentIds.remove(commentId);
      return;
    }

    try {
      await supabase.from('comments').delete().eq('id', commentId);

      final deletedCount = 1 + _countReplies(commentToDelete.replies);
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        final video = homeController.videoList.firstWhereOrNull((v) => v.id == videoId);
        if (video != null) {
          // Trừ đi đúng số lượng đã xóa
          video.commentCount.value -= deletedCount;
        }
      }

      // Cập nhật UI của comment sheet (xóa ở local)
      final parentComment = _findParentComment(commentId);
      if (parentComment != null) {
        parentComment.replies.remove(commentToDelete);
      } else {
        comments.remove(commentToDelete);
      }

    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa bình luận: ${e.toString()}');
    } finally {
      deletingCommentIds.remove(commentId);
    }
  }

  Comment? _findParentComment(String commentId) {
    for (var comment in comments) {
      if (_findCommentInReplies(commentId, comment.replies) != null) return comment;
    }
    return null;
  }
  Future<void> toggleLike(String commentId) async {
    if (currentUserId == null) return;

    final comment = _findCommentById(commentId);
    if (comment == null) return;

    final isCurrentlyLiked = comment.isLiked.value;
    comment.isLiked.value = !isCurrentlyLiked; // Optimistic update
    comment.likeCount.value += isCurrentlyLiked ? -1 : 1;

    try {
      if (isCurrentlyLiked) {
        await supabase.from('comment_likes').delete().match({
          'comment_id': commentId,
          'user_id': currentUserId!,
        });
      } else {
        await supabase.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': currentUserId!,
        });
      }
    } catch (e) {
      comment.isLiked.value = isCurrentlyLiked; // Revert on error
      comment.likeCount.value += isCurrentlyLiked ? 1 : -1;
      Get.snackbar("Lỗi", "Thao tác thất bại, vui lòng thử lại.");
    }
  }


  Comment? _findCommentById(String id) {
    for (var comment in comments) {
      if (comment.id == id) return comment;
      final foundInReply = _findCommentInReplies(id, comment.replies);
      if (foundInReply != null) return foundInReply;
    }
    return null;
  }

  Comment? _findCommentInReplies(String id, List<Comment> replies) {
    for (var reply in replies) {
      if (reply.id == id) return reply;
      final foundInReply = _findCommentInReplies(id, reply.replies);
      if (foundInReply != null) return foundInReply;
    }
    return null;
  }

  void startReply(Comment comment) {
    replyingTo.value = comment;
  }

  void cancelReply() {
    replyingTo.value = null;
  }
}
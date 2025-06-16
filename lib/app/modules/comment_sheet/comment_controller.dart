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

      final response = await supabase
          .from('comments')
          .select(_commentSelectQuery)
          .eq('video_id', videoId)
          .order('created_at', ascending: true);

      // ✅ THÊM LẠI: Lấy danh sách các bình luận mà người dùng hiện tại đã thích.
      final likedCommentsResponse = await supabase
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', currentUserId!);

      final likedCommentIds =
      likedCommentsResponse.map((like) => like['comment_id'].toString()).toSet();

      final allComments = response
          .map((json) => Comment.fromJson(json)
          .copyWith(isLiked: likedCommentIds.contains(json['id'].toString())))
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
      if (commentIdAsInt == null) return;
      await supabase.from('comments').delete().eq('id', commentIdAsInt);
      if (_deleteCommentRecursive(commentId, comments)) {
        Get.back();
        Get.snackbar("Thành công", "Đã xóa bình luận.");
      }
    } catch(e) {
      Get.snackbar("Lỗi", "Không thể xóa bình luận này.");
    }
  }

  /// ✅ THÊM LẠI: Hàm toggleLike cho bình luận, sử dụng bảng 'comment_likes'
  Future<void> toggleLike(String commentId) async {
    if (currentUserId == null) return;

    final comment = _findCommentById(commentId);
    if (comment == null) return;

    final commentIdAsInt = int.tryParse(commentId);
    if (commentIdAsInt == null) return;

    final isCurrentlyLiked = comment.isLiked.value;
    comment.isLiked.toggle();

    try {
      if (isCurrentlyLiked) {
        // Nếu đang like -> unlike (xóa record)
        await supabase.from('comment_likes').delete().match({
          'comment_id': commentIdAsInt,
          'user_id': currentUserId!,
        });
      } else {
        // Nếu chưa like -> like (thêm record)
        await supabase.from('comment_likes').insert({
          'comment_id': commentIdAsInt,
          'user_id': currentUserId!,
        });
      }
    } catch (e) {
      comment.isLiked.toggle();
      Get.snackbar("Lỗi", "Thao tác thất bại, vui lòng thử lại.");
    }
  }

  // --- CÁC HÀM HELPER ---

  void _addCommentToList(Comment comment) {
    if (replyingTo.value != null) {
      final parent = comments.firstWhereOrNull((c) => c.id == replyingTo.value!.id);
      parent?.replies.add(comment);
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

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

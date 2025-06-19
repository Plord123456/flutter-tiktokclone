// lib/services/chat_service.dart

import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/data/models/message_model.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';

class ChatService extends GetxService {
  final supabase = Supabase.instance.client;

  String get currentUserId => supabase.auth.currentUser!.id;

  Future<String?> findOrCreateConversation(String otherUserId) async {
    if (otherUserId == currentUserId) return null;
    try {
      final data = await supabase.rpc('find_or_create_conversation',
          params: {'user1_id': currentUserId, 'user2_id': otherUserId});
      return data as String?;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể bắt đầu cuộc trò chuyện: $e');
      return null;
    }
  }

  Future<List<Conversation>> getConversations() async {
    try {
      final response = await supabase.rpc('get_user_conversations',
          params: {'p_user_id': currentUserId});
      final conversations = (response as List<dynamic>)
          .map((json) =>
          Conversation.fromJson(json, currentUserId: currentUserId))
          .toList();
      return conversations;
    } catch (e) {
      print('Lỗi khi lấy danh sách cuộc trò chuyện: $e');
      return [];
    }
  }

  Future<List<Message>> getMessages(String conversationId,
      {int page = 1, int pageSize = 20}) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    try {
      final response = await supabase
          .from('messages')
          .select('*, sender:profiles!messages_sender_id_fkey(*)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(from, to);
      return response.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      print('Lỗi khi tải tin nhắn: $e');
      return [];
    }
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'content': content.trim(),
    });
  }

  // ==========================================================
  // HÀM SUBSCRIBE ĐƯỢC VIẾT LẠI HOÀN TOÀN BẰNG .stream()
  // ==========================================================
  StreamSubscription<List<Map<String, dynamic>>> subscribeToMessages(
      String conversationId, Function(Message) onNewMessage) {

    // Tạo một stream trực tiếp từ bảng 'messages'
    final stream = supabase
        .from('messages')
        .stream(primaryKey: ['id']) // Cần chỉ định khóa chính
        .eq('conversation_id', conversationId); // Lọc theo đúng conversation ID

    // Lắng nghe stream này
    final subscription = stream.listen((payload) {
      // Khi có bản ghi mới được INSERT, stream sẽ trả về một List
      // chứa tất cả các record khớp với câu query, bao gồm cả record mới.
      if (payload.isNotEmpty) {
        // Chúng ta sẽ lấy record mới nhất dựa trên thời gian tạo
        payload.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
        final lastRecord = payload.first;

        final newMessage = Message.fromJson(lastRecord);
        onNewMessage(newMessage);
      }
    });

    return subscription;
  }
}
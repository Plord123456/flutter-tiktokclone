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

  Future<void> deleteMessage(String messageId) async {
    await supabase.from('messages').delete().eq('id', messageId);
  }
  StreamSubscription<List<Map<String, dynamic>>> subscribeToMessages(
      String conversationId, Function(List<Map<String, dynamic>>) onNewPayload) {
    final stream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId);

    // Lắng nghe stream này và truyền toàn bộ payload về cho controller xử lý
    final subscription = stream.listen((payload) {
      onNewPayload(payload);
    });

    return subscription;
  }

}

import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';

class ChatService extends GetxService {
  final supabase = Supabase.instance.client;
  String get currentUserId => supabase.auth.currentUser!.id;

  /// Tìm hoặc tạo một cuộc trò chuyện giữa 2 người và trả về ID của nó.
  /// Sử dụng một Stored Procedure (RPC) trên Supabase để tối ưu hiệu suất.
  Future<String?> findOrCreateConversation(String otherUserId) async {
    if (otherUserId == currentUserId) return null;

    try {
      final data = await supabase.rpc('find_or_create_conversation', params: {
        'user1_id': currentUserId,
        'user2_id': otherUserId,
      });
      // RPC sẽ trả về conversation_id
      return data as String?;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể bắt đầu cuộc trò chuyện: $e');
      return null;
    }
  }

  /// Lấy danh sách tất cả các cuộc trò chuyện của người dùng hiện tại.
  /// Mỗi cuộc trò chuyện sẽ bao gồm thông tin của người đối diện và tin nhắn cuối cùng.
  Future<List<Conversation>> getConversations() async {
    try {
      // Dùng RPC để lấy danh sách conversations, đã join sẵn thông tin profile và last_message
      final response = await supabase
          .rpc('get_user_conversations', params: {'p_user_id': currentUserId});

      final conversations = (response as List<dynamic>)
          .map((json) => Conversation.fromJson(json, currentUserId: currentUserId))
          .toList();
      return conversations;
    } catch (e) {
      print('Lỗi khi lấy danh sách cuộc trò chuyện: $e');
      return [];
    }
  }


  /// Lấy tin nhắn của một cuộc trò chuyện cụ thể, hỗ trợ phân trang.
  Future<List<Message>> getMessages(String conversationId, {int page = 1, int pageSize = 20}) async {
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


  /// Gửi một tin nhắn mới.
  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;

    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'content': content.trim(),
    });
  }


  /// Lắng nghe tin nhắn mới trong thời gian thực.
  RealtimeChannel subscribeToMessages(String conversationId, Function(Message) onNewMessage) {
    final channel = supabase.channel('chat_$conversationId');
    channel.on<PostgresChanges>(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        // Lấy thông tin người gửi từ payload hoặc query lại nếu cần
        // Ở đây chúng ta tạm thời tạo message mà không có full profile của sender
        // Controller sẽ xử lý việc này sau.
        final newMessage = Message.fromJson(payload.newRecord);
        onNewMessage(newMessage);
      },
    ).subscribe();

    return channel;
  }
}
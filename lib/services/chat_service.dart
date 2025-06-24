import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/conversation_model.dart';
import 'package:tiktok_clone/app/data/models/message_model.dart';

class ChatService extends GetxService {
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<Conversation>> getConversations() async {
    if (_userId == null) throw Exception('User not logged in');
    try {
      final data = await _supabase
          .rpc('get_user_conversations_with_details', params: {'p_user_id': _userId});

      return (data as List).map((item) => Conversation.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final data = await _supabase
        .from('messages')
        .select('*, sender:sender_id(*)') // Hoặc `profiles:user_id(*)` tùy CSDL
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false);

    final messages = <Message>[];
    final messageMap = <String, Map<String, dynamic>>{};
    for (var item in data) {
      messageMap[item['id'].toString()] = item;
    }

    for (var item in data) {
      Message? repliedTo;
      final replyId = item['reply_to_message_id']?.toString();
      if (replyId != null && messageMap.containsKey(replyId)) {
        repliedTo = Message.fromJson(messageMap[replyId]!);
      }
      messages.add(Message.fromJson(item, repliedToMessage: repliedTo));
    }

    return messages;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
  }) async {
    if (_userId == null) return;
    await _supabase.from('messages').insert({
      'sender_id': _userId, // Sửa thành sender_id
      'conversation_id': conversationId,
      'content': content,
      'reply_to_message_id': replyToMessageId,
    });
  }

  Future<String?> findOrCreateConversation(String otherUserId) async {
    if (_userId == null) return null;
    final result = await _supabase.rpc('find_or_create_conversation',
        params: {'user1_id': _userId, 'user2_id': otherUserId});
    return result?.toString();
  }
}

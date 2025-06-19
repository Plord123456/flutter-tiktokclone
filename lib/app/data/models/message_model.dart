
import 'package:tiktok_clone/app/data/models/profile_model.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final Profile? sender; // Thông tin người gửi (username, avatar)

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      // Kiểm tra xem dữ liệu 'sender' có được join từ Supabase không
      sender: json['sender'] != null && json['sender'] is Map<String, dynamic>
          ? Profile.fromSupabase(json['sender'])
          : null,
    );
  }
}
import 'package:tiktok_clone/app/data/models/profile_model.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final Profile? sender;

  // Sửa: Đổi thành String? để nhất quán với `id`
  final String? replyToMessageId;
  final Message? repliedToMessage;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.sender,
    this.replyToMessageId,
    this.repliedToMessage,
  });

  // Sửa: Cập nhật factory để xử lý đầy đủ các trường
  factory Message.fromJson(Map<String, dynamic> json, {Message? repliedToMessage}) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at']),
      sender: json['sender'] != null && json['sender'] is Map<String, dynamic>
          ? Profile.fromSupabase(json['sender'])
          : (json['profiles'] != null ? Profile.fromJson(json['profiles']) : null),
      // Bổ sung logic còn thiếu
      replyToMessageId: json['reply_to_message_id']?.toString(),
      repliedToMessage: repliedToMessage,
    );
  }
}

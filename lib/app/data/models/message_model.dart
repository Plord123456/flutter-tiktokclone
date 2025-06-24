import 'package:tiktok_clone/app/data/models/profile_model.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final Profile? sender;
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

  // V SỬA: Thêm tham số currentUserId và sửa logic
  factory Message.fromJson(Map<String, dynamic> json,
      {Message? repliedToMessage, required String currentUserId}) {
    final profileData = json['sender'] ?? json['profiles'];

    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at']),
      // V SỬA: Truyền currentUserId xuống Profile.fromJson
      sender: profileData != null && profileData is Map<String, dynamic>
          ? Profile.fromJson(profileData, currentUserId: currentUserId)
          : null,
      replyToMessageId: json['reply_to_message_id']?.toString(),
      repliedToMessage: repliedToMessage,
    );
  }
}

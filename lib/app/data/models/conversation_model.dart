class Conversation {
  // SỬA: Đổi id thành String
  final String id;
  final String otherUserId;
  final String? otherUserUsername;
  final String? otherUserAvatarUrl;
  final String? lastMessageContent;
  final DateTime? lastMessageCreatedAt;

  Conversation({
    required this.id,
    required this.otherUserId,
    this.otherUserUsername,
    this.otherUserAvatarUrl,
    this.lastMessageContent,
    this.lastMessageCreatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['conversation_id'].toString(),
      otherUserId: json['other_user_id'].toString(),
      otherUserUsername: json['other_user_username'],
      otherUserAvatarUrl: json['other_user_avatar_url'],
      lastMessageContent: json['last_message_content'],
      lastMessageCreatedAt: json['last_message_created_at'] != null
          ? DateTime.parse(json['last_message_created_at'])
          : null,
    );
  }
}

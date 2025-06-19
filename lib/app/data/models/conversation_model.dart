
import 'package:tiktok_clone/app/data/models/profile_model.dart';

class Conversation {
  final String id;
  final String? lastMessageContent;
  final DateTime? lastMessageCreatedAt;
  final Profile otherParticipant; // Người đang trò chuyện cùng mình

  Conversation({
    required this.id,
    this.lastMessageContent,
    this.lastMessageCreatedAt,
    required this.otherParticipant,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    return Conversation(
      id: json['conversation_id'],
      lastMessageContent: json['last_message_content'],
      lastMessageCreatedAt: json['last_message_created_at'] != null
          ? DateTime.parse(json['last_message_created_at'])
          : null,
      // Tạo đối tượng Profile cho người đối diện từ dữ liệu trả về của RPC
      otherParticipant: Profile.fromSupabase({
        'id': json['other_user_id'],
        'username': json['other_user_username'],
        'avatar_url': json['other_user_avatar_url'],
        // Các trường khác có thể null hoặc mặc định
        'full_name': null,
        'follower_count': 0,
        'following_count': 0,
        'post_count': 0,
        'likes_count': 0,
      }),
    );
  }
}
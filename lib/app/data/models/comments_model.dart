import 'package:get/get.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart'; // Đảm bảo đường dẫn này đúng

class Comment {
  final String id;
  final String content;
  final String userId;
  final String videoId;
  final DateTime createdAt;

  // NOTE: Thông tin người dùng được lồng vào qua đối tượng Profile
  // Điều này giúp cấu trúc rõ ràng hơn.
  final Profile profile;

  // NOTE: parentCommentId nên là String? để tương thích với UUID từ Supabase.
  final String? parentCommentId;

  // FIX: Khai báo và khởi tạo đầy đủ các biến Rx.
  // Chúng là `late final` vì chỉ được gán giá trị một lần duy nhất trong constructor.
  late final RxInt likeCount;
  late final RxBool isLiked;
  late final RxList<Comment> replies;

  // NOTE: Constructor nhận các giá trị 'initial' để thiết lập state ban đầu.
  // Đây là cách làm nhất quán và an toàn.
  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.videoId,
    required this.createdAt,
    required this.profile,
    this.parentCommentId,
    required int initialLikeCount,
    required bool initialIsLiked,
    List<Comment>? initialReplies,
  }) {
    // Gán giá trị cho các biến Rx bằng cách dùng `.obs`
    likeCount = initialLikeCount.obs;
    isLiked = initialIsLiked.obs;
    replies = (initialReplies ?? <Comment>[]).obs;
  }

  // Tiện ích để lấy username và avatarUrl một cách an toàn
  RxString get username => profile.username;
  RxString get avatarUrl => profile.avatarUrl;

  /// FIX: fromJson được viết lại hoàn toàn để an toàn và chính xác.
  /// Nó nhận vào `currentUserId` để có thể tính toán `isLiked`.
  factory Comment.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    // Lấy thông tin về lượt thích từ key 'comment_likes' (như đã định nghĩa trong Controller)
    final likesData = json['comment_likes'] as List? ?? [];

    // Tính toán isLiked và likeCount ngay tại đây
    final bool isLikedByUser = likesData.any((like) => like['user_id'] == currentUserId);
    final int likeCount = likesData.length;

    return Comment(
      id: json['id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      videoId: json['video_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),

      // Sử dụng Profile.fromJson để tái sử dụng logic
      // `json['profiles']` là kết quả của join `profiles!inner(...)`
      profile: Profile.fromJson(json['profiles'] as Map<String, dynamic>? ?? {}),

      parentCommentId: json['parent_comment_id']?.toString(),

      // Truyền các giá trị đã tính toán vào constructor
      initialIsLiked: isLikedByUser,
      initialLikeCount: likeCount,

      // Replies sẽ được thêm vào sau trong logic của controller
      initialReplies: [],
    );
  }

  /// FIX: copyWith hoạt động chính xác, bảo toàn giá trị và không gây lỗi.
  Comment copyWith({
    String? id,
    String? content,
    String? userId,
    String? videoId,
    DateTime? createdAt,
    Profile? profile,
    String? parentCommentId,
    int? likeCount,
    bool? isLiked,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      videoId: videoId ?? this.videoId,
      createdAt: createdAt ?? this.createdAt,
      profile: profile ?? this.profile,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      // Lấy giá trị hiện tại từ biến Rx nếu không có giá trị mới được cung cấp
      initialLikeCount: likeCount ?? this.likeCount.value,
      initialIsLiked: isLiked ?? this.isLiked.value,
      initialReplies: replies ?? this.replies.toList(),
    );
  }
}
class Message {
  final String? id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final String? replyTo; // parent message id for threading
  final DateTime createdAt;
  final List<MessageReply> replies;

  Message({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.replyTo,
    DateTime? createdAt,
    List<MessageReply>? replies,
  })  : createdAt = createdAt ?? DateTime.now(),
        replies = replies ?? [];

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['_id']?.toString(),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? '',
      message: map['message'] ?? '',
      replyTo: map['replyTo'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      replies: (map['replies'] as List?)?.map((e) => MessageReply.fromMap(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'replyTo': replyTo,
      'createdAt': createdAt.toIso8601String(),
      'replies': replies.map((r) => r.toMap()).toList(),
    };
  }
}

class MessageReply {
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  MessageReply({
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MessageReply.fromMap(Map<String, dynamic> map) {
    return MessageReply(
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

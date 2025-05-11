class MessageModel {
  final String username;
  final String message;
  final String time;
  final String messageId;
  final String status;
  bool sent;

  MessageModel(
      {required this.message,
      required this.time,
      required this.username,
      required this.messageId,
      required this.status,
      this.sent = false});

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "message": message,
      "time": time,
      "messageId": messageId,
      "status": status,
      "sent": sent
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json["username"],
      message: json["message"],
      messageId: json["messageId"],
      status: json["status"],
      time: json["time"],
      sent: json["sent"] ?? false,
    );
  }
}

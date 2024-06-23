class MessageModel {
  final String username;
  final String message;
  final String time;
  bool sent;

  MessageModel(
      {required this.message,
      required this.time,
      required this.username,
      this.sent = false});

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "message": message,
      "time": time,
      "sent": sent
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json["username"],
      message: json["message"],
      time: json["time"],
      sent: json["sent"] ?? false,
    );
  }
}

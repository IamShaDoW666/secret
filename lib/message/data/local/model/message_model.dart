class MessageModel {
  final String id;
  final String username;
  final String message;
  final String time;
  String status;
  bool sent;

  MessageModel(
      {required this.id,
      required this.message,
      required this.time,
      required this.username,
      required this.status,
      this.sent = false});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "message": message,
      "time": time,
      "status": status,
      "sent": sent
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json["id"],
      username: json["username"],
      message: json["message"],
      status: json["status"],
      time: json["time"],
      sent: json["sent"] ?? false,
    );
  }
}

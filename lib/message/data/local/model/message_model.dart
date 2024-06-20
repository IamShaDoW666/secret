class MessageModel {
  final String username;
  final String message;
  final String time;

  MessageModel({
    required this.message,
    required this.time,
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "message": message,
      "time": time,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json["username"],
      message: json["message"],
      time: json["time"],
    );
  }
}

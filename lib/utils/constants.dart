class Constants {
  static const String taskKey = 'tasks';
  static const String messageKey = 'messages';
  // static const String username = "Milan";
  static const String firebaseToken = "firebase-token";
  static const String localhost = "localhost";
  static const String livehost = "https://test.milanpramod.online";
  static const bool productionEnv = false;
  static const String environment = "environment";
  static const String usernameKey = "username";
}

class EVENTS {
  static const String newMessage = 'NEW_MESSAGE';
  static const String connections = 'CONNECTIONS';
  static const String upstream = 'UPSTREAM';
  static const String downstream = 'DOWNSTREAM';
  static const String sendMessage = 'SEND_MESSAGE';
  static const String poke = 'POKE';
  static const String typing = 'TYPING_CLIENT';
  static const String typingServer = 'TYPING';
  static const String deliveryAck = 'DELIVERY_ACK';
  static const String readAck = 'READ_ACK';
}

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/utils/constants.dart';
import 'package:task_manager_app/utils/logger.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // Handle background message
  logger.d('Handling a background message');
  // You can also access the data payload here
  logger.d('Data: ${message.data['message']}');
  sendRecievedAck(message.data['message']['id']);
}

Future<http.Response> sendRecievedAck(String msgId) {
  String username = getStringAsync(Constants.usernameKey);
  return http.post(
    Uri.parse(
        '${getBoolAsync(Constants.environment) ? Constants.livehost : getStringAsync(Constants.localhost)}/recievedAck'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body:
        jsonEncode(<String, String>{'messageId': msgId, 'username': username}),
  );
}

Future<http.Response> sendDeliveryAck(String msgId) {
  String username = getStringAsync(Constants.usernameKey);
  return http.post(
    Uri.parse(
        '${getBoolAsync(Constants.environment) ? Constants.livehost : getStringAsync(Constants.localhost)}/deliveryAck'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body:
        jsonEncode(<String, String>{'messageId': msgId, 'username': username}),
  );
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    await _firebaseMessaging
        .subscribeToTopic(getStringAsync(Constants.usernameKey));
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
}

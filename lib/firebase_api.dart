import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_app/utils/common.dart';
import 'package:task_manager_app/utils/constants.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {}

Future<http.Response> sendSubscription(String token) {
  return http.post(
    Uri.parse('${Constants.localhost}/subscribe'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, String>{'token': token, 'username': Constants.username}),
  );
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    String? storedToken = await getStoredToken();

    if (fCMToken != null && storedToken != fCMToken) {
      await sendSubscription(fCMToken);
      await storeTokenLocally(fCMToken);
    }

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
      sendSubscription(fcmToken);
      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    }).onError((err) {
      // Error getting token.
    });
  }
}

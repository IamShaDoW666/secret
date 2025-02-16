import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/utils/common.dart';
import 'package:task_manager_app/utils/constants.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {}

Future<http.Response> sendSubscription(String token) {
  String username = getStringAsync(Constants.usernameKey);
  return http.post(
    Uri.parse(
        '${getBoolAsync(Constants.environment) ? Constants.livehost : Constants.localhost}/subscribe'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'token': token, 'username': username}),
  );
}

Future<String?> getTokenFromServer() async {
  String username = getStringAsync(Constants.usernameKey);
  var res = await http.get(
    Uri.parse(
        '${getBoolAsync(Constants.environment) ? Constants.livehost : Constants.localhost}/token?username=$username'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  if (res.statusCode == 200) {
    Map<String, dynamic> jsonResponse = json.decode(res.body);
    if (jsonResponse['success'] == true && jsonResponse.containsKey('token')) {
      // Return the parsed JSON as a Map
      return jsonResponse['token'];
    } else {
      // Handle the case where the API response does not match expected format
      throw Exception('Invalid API response');
    }
  } else {
    // Handle HTTP error
    throw Exception('Failed to load data from server');
  }
}

Future<void> initToken() async {
  final firebaseMessaging = FirebaseMessaging.instance;
  final fCMToken = await firebaseMessaging.getToken();
  String? storedToken = await getStoredToken();
  String? serverToken = await getTokenFromServer();
  // print('server: $serverToken');
  // print('stored: $storedToken');
  // print('firebase: $fCMToken');
  if (fCMToken != null) {
    if ((fCMToken != storedToken) || (fCMToken != serverToken)) {
      sendSubscription(fCMToken);
      await storeTokenLocally(fCMToken);
      // print('TOOOOOO SAAAAAAAAVEE');
    }
  }
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    await initToken();
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      String? storedToken = await getStoredToken();
      String? serverToken = await getTokenFromServer();

      if ((fcmToken != storedToken) || (fcmToken != serverToken)) {
        sendSubscription(fcmToken);
        await storeTokenLocally(fcmToken);
      }
      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    }).onError((err) {
      // Error getting token.
    });
  }
}

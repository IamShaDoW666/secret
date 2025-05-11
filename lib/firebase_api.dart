import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/utils/common.dart';
import 'package:task_manager_app/utils/constants.dart';
import 'package:task_manager_app/utils/logger.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // Handle background message
  logger.d('Handling a background message: ${message.messageId}');
  // You can also access the data payload here
  logger.d('Data: ${message.data}');
  sendDeliveryAck(message.data['messageId']);
}

Future<http.Response> sendSubscription(String token) {
  String username = getStringAsync(Constants.usernameKey);
  return http.post(
    Uri.parse(
        '${getBoolAsync(Constants.environment) ? Constants.livehost : getStringAsync(Constants.localhost)}/subscribe'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'token': token, 'username': username}),
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
    body: jsonEncode(<String, String>{'messageId': msgId, 'username': username}),
  );
}

Future<String?> getTokenFromServer() async {
  String username = getStringAsync(Constants.usernameKey);
  var res = await http.get(
    Uri.parse(
        '${getBoolAsync(Constants.environment) ? Constants.livehost : getStringAsync(Constants.localhost)}/token?username=$username'),
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
  try {
    String? serverToken = await getTokenFromServer();
    if (fCMToken!.isNotEmpty) {
      if ((fCMToken != storedToken) || (fCMToken != serverToken)) {
        sendSubscription(fCMToken);
        await storeTokenLocally(fCMToken);
        // print('TOOOOOO SAAAAAAAAVEE');
        // print('$fCMToken $storedToken $serverToken');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
  // print('server: $serverToken');
  // print('stored: $storedToken');
  // print('firebase: $fCMToken');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    await initToken();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.d('Message data: ${message.data}');
      sendDeliveryAck(message.data['messageId']);
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      String? storedToken = await getStoredToken();
      try {
        String? serverToken = await getTokenFromServer();

        if ((fcmToken != storedToken) || (fcmToken != serverToken)) {
          await sendSubscription(fcmToken);
          await storeTokenLocally(fcmToken);
        }
      } catch (e) {
        print('Error: $e');
      }
      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    }).onError((err) {
      // Error getting token.
    });
  }
}

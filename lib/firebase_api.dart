import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_app/message/data/local/data_sources/messages_data_provider.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // SharedPreferences? prefs;
  // MessageDataProvider messageDataProvider = MessageDataProvider(prefs);
  // print("Title: ${message.notification!.title!}");
  // var messageModel = MessageModel(
  //     message: message.notification!.title!, time: "12:00", username: "Milan");
  // messageDataProvider.createMessage(messageModel);
  // var msgs = await messageDataProvider.getMessages();
  // msgs.map((e) => print(e.message));
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    // final fCMToken = await _firebaseMessaging.getToken();
    // print('Token: $fCMToken');

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
}

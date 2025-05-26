import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:task_manager_app/firebase_api.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/message/presentation/bloc/messages_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/utils/logger.dart';

class NotificationSetup extends StatefulWidget {
  final Widget child;
  const NotificationSetup({super.key, required this.child});

  @override
  State<NotificationSetup> createState() => _NotificationSetupState();
}

class _NotificationSetupState extends State<NotificationSetup> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((message) async {
      final String jsonString = message.data['message'];
      final Map<String, dynamic> messageData = jsonDecode(jsonString);
      logger.d('New message received: $messageData');
      var messageModel = MessageModel(
          id: messageData["id"],
          status: messageData["status"] ?? "RECEIVED",
          message: messageData["message"],
          time: messageData["time"],
          sent: false,
          username: messageData["username"]);
      context
          .read<MessagesBloc>()
          .add(AddNewMessageForegroundEvent(messageModel: messageModel));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

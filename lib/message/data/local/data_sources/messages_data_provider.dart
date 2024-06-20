import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/utils/exception_handler.dart';

import '../../../../utils/constants.dart';

class MessageDataProvider {
  List<MessageModel> messages = [];
  SharedPreferences? prefs;

  MessageDataProvider(this.prefs);

  Future<List<MessageModel>> getMessages() async {
    try {
      final List<String>? savedMessages =
          prefs!.getStringList(Constants.messageKey);
      if (savedMessages != null) {
        messages = savedMessages
            .map((messageJson) =>
                MessageModel.fromJson(json.decode(messageJson)))
            .toList();
      }
      return messages;
    } catch (e) {
      throw Exception(handleException(e));
    }
  }

  Future<void> createMessage(MessageModel messageModel) async {
    try {
      messages.add(messageModel);
      final List<String> messageJsonList =
          messages.map((message) => json.encode(message.toJson())).toList();
      await prefs!.setStringList(Constants.messageKey, messageJsonList);
    } catch (exception) {
      throw Exception(handleException(exception));
    }
  }

  Future<List<MessageModel>> deleteMessage(MessageModel messageModel) async {
    try {
      messages.remove(messageModel);
      final List<String> messageJsonList =
          messages.map((message) => json.encode(message.toJson())).toList();
      prefs!.setStringList(Constants.messageKey, messageJsonList);
      return messages;
    } catch (exception) {
      throw Exception(handleException(exception));
    }
  }

  Future<List<MessageModel>> clearMessages() async {
    try {
      messages.clear();
      final List<String> messageJsonList =
          messages.map((message) => json.encode(message.toJson())).toList();
      prefs!.setStringList(Constants.messageKey, messageJsonList);
      return messages;
    } catch (exception) {
      throw Exception(handleException(exception));
    }
  }
}

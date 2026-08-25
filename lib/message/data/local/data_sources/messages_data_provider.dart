import 'dart:convert';
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/utils/exception_handler.dart';

import '../../../../utils/constants.dart';

class MessageDataProvider {
  List<MessageModel> messages = [];

  MessageDataProvider();

  Future<List<MessageModel>> getMessages() async {
    try {
      final List<String>? savedMessages =
          getStringListAsync(Constants.messageKey);
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
      // await prefs!.setStringList(Constants.messageKey, messageJsonList);
      await setValue(Constants.messageKey, messageJsonList);
    } catch (exception) {
      throw Exception(handleException(exception));
    }
  }

  Future<List<MessageModel>> deleteMessage(MessageModel messageModel) async {
    try {
      messages.remove(messageModel);
      final List<String> messageJsonList =
          messages.map((message) => json.encode(message.toJson())).toList();
      // prefs!.setStringList(Constants.messageKey, messageJsonList);
      await setValue(Constants.messageKey, messageJsonList);
      return messages;
    } catch (exception) {
      throw Exception(handleException(exception));
    }
  }

  Future<List<MessageModel>> updateMessage(MessageModel messageModel) async {
    try {
      final index =
          messages.indexWhere((message) => message.id == messageModel.id);
      if (index != -1) {
        messages[index] = messageModel;
        final List<String> messageJsonList =
            messages.map((message) => json.encode(message.toJson())).toList();
        // prefs!.setStringList(Constants.messageKey, messageJsonList);
        await setValue(Constants.messageKey, messageJsonList);
      }
      return messages;
    } catch (exception) {
      throw Exception(handleException(exception));
    }
  }

  Future<List<MessageModel>> readMessage(String messageId) async {
    try {
      final index = messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        final message = messages[index];
        message.status = "READ"; // Update status to READ
        messages[index] = message; // Update the message in the list
        final List<String> messageJsonList =
            messages.map((message) => json.encode(message.toJson())).toList();
        // prefs!.setStringList(Constants.messageKey, messageJsonList);
        await setValue(Constants.messageKey, messageJsonList);
      }
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
      print(messageJsonList);
      // prefs!.setStringList(Constants.messageKey, messageJsonList);
      await setValue(Constants.messageKey, messageJsonList);
      return messages;
    } catch (exception) {
      throw Exception(handleException(exception));
    }
  }
}

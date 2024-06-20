import 'package:task_manager_app/message/data/local/data_sources/messages_data_provider.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';

class MessageRepository {
  final MessageDataProvider messageDataProvider;

  MessageRepository({required this.messageDataProvider});

  Future<List<MessageModel>> getMessages() async {
    return await messageDataProvider.getMessages();
  }

  Future<void> createNewMessage(MessageModel messageModel) async {
    return await messageDataProvider.createMessage(messageModel);
  }

  Future<List<MessageModel>> deleteMessage(MessageModel messageModel) async {
    return await messageDataProvider.deleteMessage(messageModel);
  }

  Future<List<MessageModel>> clearMessage() async {
    return await messageDataProvider.clearMessages();
  }
}

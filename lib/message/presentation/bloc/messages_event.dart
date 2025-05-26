part of 'messages_bloc.dart';

@immutable
sealed class MessagesEvent {}

class AddNewMessageEvent extends MessagesEvent {
  final MessageModel messageModel;

  AddNewMessageEvent({required this.messageModel});
}

class AddNewMessageForegroundEvent extends MessagesEvent {
  final MessageModel messageModel;

  AddNewMessageForegroundEvent({required this.messageModel});
}

class FetchMessageEvent extends MessagesEvent {}

class ReadAckEvent extends MessagesEvent {
  final String messageId;

  ReadAckEvent({required this.messageId});
}

class UpdateMessageEvent extends MessagesEvent {
  final MessageModel messageModel;

  UpdateMessageEvent({required this.messageModel});
}

class ClearMessagesEvent extends MessagesEvent {}

class DeleteMessageEvent extends MessagesEvent {
  final MessageModel messageModel;

  DeleteMessageEvent({required this.messageModel});
}

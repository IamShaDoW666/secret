part of 'messages_bloc.dart';

@immutable
sealed class MessagesEvent {}

class AddNewMessageEvent extends MessagesEvent {
  final MessageModel messageModel;

  AddNewMessageEvent({required this.messageModel});
}

class FetchMessageEvent extends MessagesEvent {}

class ClearMessagesEvent extends MessagesEvent {}

class DeleteMessageEvent extends MessagesEvent {
  final MessageModel messageModel;

  DeleteMessageEvent({required this.messageModel});
}

part of 'messages_bloc.dart';

@immutable
sealed class MessagesState {}

final class FetchMessagesSuccess extends MessagesState {
  final List<MessageModel> messages;
  final bool isSearching;

  FetchMessagesSuccess({required this.messages, this.isSearching = false});
}

final class AddMessagesSuccess extends MessagesState {}

final class LoadMessageFailure extends MessagesState {
  final String error;

  LoadMessageFailure({required this.error});
}

final class AddMessageFailure extends MessagesState {
  final String error;

  AddMessageFailure({required this.error});
}

final class MessagesLoading extends MessagesState {}

final class UpdateMessageFailure extends MessagesState {
  final String error;

  UpdateMessageFailure({required this.error});
}

final class UpdateMessageSuccess extends MessagesState {}

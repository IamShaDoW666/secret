import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/model/message_model.dart';
import '../../data/repository/message_repository.dart';

part 'messages_event.dart';

part 'messages_state.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository messageRepository;

  MessagesBloc(this.messageRepository)
      : super(FetchMessagesSuccess(messages: const [])) {
    on<AddNewMessageEvent>(_addNewMessage);
    on<FetchMessageEvent>(_fetchMessages);
    on<DeleteMessageEvent>(_deleteMessage);
    on<ClearMessagesEvent>(_clearMessages);
  }

  _addNewMessage(AddNewMessageEvent event, Emitter<MessagesState> emit) async {
    emit(MessagesLoading());
    try {
      if (event.messageModel.message.trim().isEmpty) {
        return emit(AddMessageFailure(error: 'Message cannot be blank'));
      }
      // if (event.messageModel.description.trim().isEmpty) {
      //   return emit(
      //       AddMessageFailure(error: 'Message description cannot be blank'));
      // }
      // if (event.messageModel.startDateTime == null) {
      //   return emit(AddMessageFailure(error: 'Missing message start date'));
      // }
      // if (event.messageModel.stopDateTime == null) {
      //   return emit(AddMessageFailure(error: 'Missing message stop date'));
      // }
      await messageRepository.createNewMessage(event.messageModel);
      emit(AddMessagesSuccess());
      final messages = await messageRepository.getMessages();
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(AddMessageFailure(error: exception.toString()));
    }
  }

  void _fetchMessages(
      FetchMessageEvent event, Emitter<MessagesState> emit) async {
    emit(MessagesLoading());
    try {
      final messages = await messageRepository.getMessages();
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(LoadMessageFailure(error: exception.toString()));
    }
  }

  _deleteMessage(DeleteMessageEvent event, Emitter<MessagesState> emit) async {
    emit(MessagesLoading());
    try {
      final messages =
          await messageRepository.deleteMessage(event.messageModel);
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(LoadMessageFailure(error: exception.toString()));
    }
  }

  _clearMessages(ClearMessagesEvent event, Emitter<MessagesState> emit) async {
    emit(MessagesLoading());
    try {
      final messages = await messageRepository.clearMessage();
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(LoadMessageFailure(error: exception.toString()));
    }
  }
}

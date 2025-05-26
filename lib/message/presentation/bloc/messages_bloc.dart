import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/firebase_api.dart';
import 'package:task_manager_app/utils/logger.dart';

import '../../data/local/model/message_model.dart';
import '../../data/repository/message_repository.dart';

part 'messages_event.dart';

part 'messages_state.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository messageRepository;

  MessagesBloc(this.messageRepository)
      : super(FetchMessagesSuccess(messages: const [])) {
    on<AddNewMessageEvent>(_addNewMessage);
    on<AddNewMessageForegroundEvent>(_addNewMessageForeground);
    on<FetchMessageEvent>(_fetchMessages);
    on<DeleteMessageEvent>(_deleteMessage);
    on<ClearMessagesEvent>(_clearMessages);
    on<UpdateMessageEvent>(_updateMessage);
    on<ReadAckEvent>(_readAck);
  }

  _addNewMessage(AddNewMessageEvent event, Emitter<MessagesState> emit) async {
    // emit(MessagesLoading());
    try {
      if (event.messageModel.message.trim().isEmpty) {
        return emit(AddMessageFailure(error: 'Message cannot be blank'));
      }
      await messageRepository.createNewMessage(event.messageModel);
      emit(AddMessagesSuccess());
      final messages = await messageRepository.getMessages();
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(AddMessageFailure(error: exception.toString()));
    }
  }

  _addNewMessageForeground(
      AddNewMessageForegroundEvent event, Emitter<MessagesState> emit) async {
    // emit(MessagesLoading());
    try {
      if (event.messageModel.message.trim().isEmpty) {
        return emit(AddMessageFailure(error: 'Message cannot be blank'));
      }
      // await messageRepository.createNewMessage(event.messageModel);
      sendDeliveryAck(event.messageModel.id);
    } catch (exception) {
      emit(AddMessageFailure(error: exception.toString()));
    }
  }

  _readAck(ReadAckEvent event, Emitter<MessagesState> emit) async {
    // emit(MessagesLoading());
    try {
      await messageRepository.readAck(event.messageId);
      final messages = await messageRepository.getMessages();
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(LoadMessageFailure(error: exception.toString()));
    }
  }

  _updateMessage(UpdateMessageEvent event, Emitter<MessagesState> emit) async {
    try {
      if (event.messageModel.message.trim().isEmpty) {
        return emit(UpdateMessageFailure(error: 'Message cannot be blank'));
      }
      await messageRepository.updateMessage(event.messageModel);
      emit(UpdateMessageSuccess());
      final messages = await messageRepository.getMessages();
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(UpdateMessageFailure(error: exception.toString()));
    }
  }

  void _fetchMessages(
      FetchMessageEvent event, Emitter<MessagesState> emit) async {
    // emit(MessagesLoading());
    try {
      final messages = await messageRepository.getMessages();
      emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(LoadMessageFailure(error: exception.toString()));
    }
  }

  _deleteMessage(DeleteMessageEvent event, Emitter<MessagesState> emit) async {
    // emit(MessagesLoading());
    try {
      final messages =
          await messageRepository.deleteMessage(event.messageModel);
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(LoadMessageFailure(error: exception.toString()));
    }
  }

  _clearMessages(ClearMessagesEvent event, Emitter<MessagesState> emit) async {
    // emit(MessagesLoading());
    try {
      final messages = await messageRepository.clearMessage();
      return emit(FetchMessagesSuccess(messages: messages));
    } catch (exception) {
      emit(LoadMessageFailure(error: exception.toString()));
    }
  }
}

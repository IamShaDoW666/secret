import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:task_manager_app/components/build_text_field.dart';
import 'package:task_manager_app/components/widgets.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/message/presentation/bloc/messages_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/utils/color_palette.dart';
import 'package:task_manager_app/utils/font_sizes.dart';

import '../../../utils/util.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late io.Socket socket;
  TextEditingController messageController = TextEditingController();

  void connectSocket() {
    socket = io.io("http://192.168.18.38:5000", <String, dynamic>{
      'transports': ['websocket']
    });
    socket.connect();
    socket
        .onConnect((data) => print("CONNECTED +++++++++++++++++++++++++++++"));
    socket.on("ROOM_MESSAGE", (data) {
      var message = MessageModel(
          message: data["message"], time: "0:00", username: "Milan");
      context
          .read<MessagesBloc>()
          .add(AddNewMessageEvent(messageModel: message));
    });
    socket.onConnectError((data) => print(data.toString()));
    socket.onDisconnect((data) {
      print("----------------------------------");
      context.read<MessagesBloc>().add(ClearMessagesEvent());
    });
  }

  @override
  void initState() {
    context.read<MessagesBloc>().add(FetchMessageEvent());
    super.initState();
    connectSocket();
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    messageController.clear();
    var message = MessageModel(message: text, time: "0:00", username: "Megha");
    context.read<MessagesBloc>().add(AddNewMessageEvent(messageModel: message));
    socket.emit("SEND_ROOM_MESSAGE",
        <String, dynamic>{"roomId": "1", "message": text, "username": "Megha"});
    context.read<MessagesBloc>().add(FetchMessageEvent());
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: messageController,
              onSubmitted: (value) {},
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(messageController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: Text(
                message.username,
                style: const TextStyle(fontSize: 8),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.username,
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(message.message),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Secret"),
        ),
        body: Center(
          child: BlocConsumer<MessagesBloc, MessagesState>(
            listener: (context, state) {
              if (state is LoadMessageFailure) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(getSnackBar(state.error, kRed));
              }

              if (state is AddMessageFailure) {
                context.read<MessagesBloc>().add(FetchMessageEvent());
              }
            },
            builder: (context, state) {
              if (state is MessagesLoading) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }

              if (state is LoadMessageFailure) {
                return Center(
                  child: buildText(state.error, kBlackColor, textMedium,
                      FontWeight.normal, TextAlign.center, TextOverflow.clip),
                );
              }
              if (state is FetchMessagesSuccess) {
                return state.messages.isNotEmpty
                    ? Column(
                        children: [
                          Flexible(
                            child: ListView.builder(
                              // reverse:
                              //     true, // To keep the latest messages at the bottom
                              padding: const EdgeInsets.all(8.0),
                              itemCount: state.messages.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _buildMessageBubble(
                                    state.messages[index]);
                              },
                            ),
                          ),
                          const Divider(height: 1.0),
                          _buildTextComposer(),
                        ],
                      )
                    : Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/tasks.svg',
                              height: size.height * .20,
                              width: size.width,
                            ),
                            const SizedBox(
                              height: 50,
                            ),
                            buildText(
                                'Schedule your tasks',
                                kBlackColor,
                                textBold,
                                FontWeight.w600,
                                TextAlign.center,
                                TextOverflow.clip),
                            buildText(
                                'Manage your task schedule easily\nand efficiently',
                                kBlackColor.withOpacity(.5),
                                textSmall,
                                FontWeight.normal,
                                TextAlign.center,
                                TextOverflow.clip),
                          ],
                        ),
                      );
              }
              return Container();
            },
          ),
        ));
  }
}

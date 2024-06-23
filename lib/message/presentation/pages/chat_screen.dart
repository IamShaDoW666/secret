import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:task_manager_app/components/widgets.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/message/presentation/bloc/messages_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/utils/color_palette.dart';
import 'package:task_manager_app/utils/constants.dart';
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
  final ScrollController _scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  bool connected = false;
  bool inChat = false;

  void connectSocket() {
    socket = io.io(
        "http://192.168.18.38:5000",
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setQuery({'username': Constants.username})
            .build());
    socket.connect();

    socket.onConnect((data) {
      setState(() {
        connected = true;
      });

      // New message event
      socket.on(EVENTS.newMessage, (data) {
        var message = MessageModel(
            message: data["message"],
            time: data["time"],
            username: data["username"]);
        context
            .read<MessagesBloc>()
            .add(AddNewMessageEvent(messageModel: message));
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });

      socket.on(EVENTS.connections, (data) {
        if (data["connections"] > 1) {
          setState(() {
            inChat = true;
          });
        } else {
          setState(() {
            inChat = false;
          });
        }
      });
    });

    socket.on(EVENTS.upstream, (data) {
      List<MessageModel>? messages = List.empty();
      messages = (data as List).map((i) => MessageModel.fromJson(i)).toList();
      for (var message in messages) {
        if (message.username != Constants.username) {
          context
              .read<MessagesBloc>()
              .add(AddNewMessageEvent(messageModel: message));
        }
      }
      socket.emit(EVENTS.downstream, Constants.username);
    });

    socket.onConnectError((data) {
      setState(() {
        connected = false;
        inChat = false;
      });
    });
    socket.onDisconnect((data) {
      setState(() {
        inChat = false;
        connected = false;
      });
      // context.read<MessagesBloc>().add(ClearMessagesEvent());
    });
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          // show = false;
        });
      }
    });
    context.read<MessagesBloc>().add(FetchMessageEvent());
    connectSocket();
  }

  @override
  void dispose() {
    socket.close();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    messageController.clear();
    var message = MessageModel(
        message: text,
        time: DateFormat('HH:mm').format(DateTime.now()),
        username: Constants.username,
        sent: true);
    context.read<MessagesBloc>().add(AddNewMessageEvent(messageModel: message));
    socket.emit(EVENTS.sendMessage, <String, dynamic>{
      "roomId": "1",
      "message": text,
      "username": message.username
    });
    context.read<MessagesBloc>().add(FetchMessageEvent());
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              focusNode: focusNode,
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: message.username == 'Malu'
                ? Colors.pink.shade100.withAlpha(150)
                : Colors.blue.shade100.withAlpha(150)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Container(
            //   margin: const EdgeInsets.only(right: 16.0),
            //   child: CircleAvatar(
            //     child: Text(
            //       message.username,
            //       style: const TextStyle(fontSize: 8),
            //     ),
            //   ),
            // ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(message.username,
                      style: Theme.of(context).textTheme.titleSmall),
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      message.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      message.time,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: Colors.black54),
                    ),
                  )
                ],
              ).paddingSymmetric(horizontal: 8, vertical: 4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                connected ? "Connected" : "Disconnected",
                style: TextStyle(
                    color: connected ? Colors.black : Colors.redAccent),
              ),
              16.width,
              inChat
                  ? AvatarGlow(
                      glowColor: Colors.greenAccent,
                      glowShape: BoxShape.circle,
                      animate: true,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                    )
                  : const Offstage()
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined,
                color: Colors.black),
            onPressed: () {
              socket.close();
              socket.disconnect();
              socket.dispose();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
                onPressed: () {
                  context.read<MessagesBloc>().add(ClearMessagesEvent());
                },
                icon: const Icon(Icons.clear_all)),
            connected
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                  ).paddingAll(8)
                : IconButton(
                    onPressed: () {
                      socket.close();
                      socket.disconnect();
                      socket.dispose();
                      connectSocket();
                    },
                    icon: const Icon(
                      Icons.signal_wifi_connected_no_internet_4_outlined,
                      color: Colors.red,
                    ).paddingAll(8))
          ],
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
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8.0),
                              itemCount: state.messages.length + 1,
                              itemBuilder: (BuildContext context, int index) {
                                if (index == state.messages.length) {
                                  return Container(
                                    height: 100,
                                  );
                                }
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
                                'No Messages',
                                kBlackColor,
                                textBold,
                                FontWeight.w600,
                                TextAlign.center,
                                TextOverflow.clip),
                            buildText(
                                'Send a message',
                                kBlackColor.withOpacity(.5),
                                textSmall,
                                FontWeight.normal,
                                TextAlign.center,
                                TextOverflow.clip),
                            _buildTextComposer(),
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

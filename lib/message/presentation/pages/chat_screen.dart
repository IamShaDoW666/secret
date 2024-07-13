import 'dart:convert';
import 'dart:ui';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'package:task_manager_app/components/build_text_field.dart';
import 'package:task_manager_app/components/widgets.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/message/presentation/bloc/messages_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/utils/color_palette.dart';
import 'package:task_manager_app/utils/common.dart';
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
  String lastOnline = '-';
  final String deviceUsername = getStringAsync(Constants.usernameKey);
  void connectSocket() {
    print('--------------------------- ${deviceUsername}');
    print(io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({'username': deviceUsername})
        .build());
    socket = io.io(
        Constants.productionEnv ? Constants.livehost : Constants.localhost,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setQuery({'username': deviceUsername})
            .build());
    // io.OptionBuilder()
    //     .setTransports(['websocket'])
    //     .disableAutoConnect()
    //     .setQuery({'username': deviceUsername})
    //     .build());
    print('+++++++++++++++++++++++++++ ${deviceUsername}');
    socket.connect();

    socket.onConnect((data) {
      setState(() {
        connected = true;
        if (getStringListAsync(Constants.messageKey)!.isNotEmpty) scrollDown();
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
        scrollDown();
      });

      socket.on(EVENTS.connections, (data) {
        if (data["connections"] > 1) {
          setState(() {
            inChat = true;
          });
        } else {
          getLastOnline();
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
        if (message.username != deviceUsername) {
          context
              .read<MessagesBloc>()
              .add(AddNewMessageEvent(messageModel: message));
        }
      }
      // scrollDown();
      _scrollController.jumpToBottom();
      socket.emit(EVENTS.downstream, deviceUsername);
    });

    socket.onConnectError((data) {
      // print(data);
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
    });
  }

  Future<void> getLastOnline() async {
    var res = await http.get(
      Uri.parse(
          '${Constants.productionEnv ? Constants.livehost : Constants.localhost}/last-online?username=${getReciever(deviceUsername)}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (res.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(res.body);
      DateTime utcTime = DateTime.parse(jsonResponse['data']['lastOnline']);
      int differenceInDays = DateTime.now().difference(utcTime).inDays;
      String formattedTime;
      if (differenceInDays == 0) {
        // Display in 12-hour format if it's today
        formattedTime = DateFormat('h:mm a').format(utcTime.toLocal());
      } else {
        formattedTime = DateFormat('dd MMM h:mm a').format(utcTime.toLocal());
      }
      setState(() {
        lastOnline = 'Last Online: $formattedTime';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
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
    focusNode.dispose();
    messageController.dispose();
    super.dispose();
  }

  void scrollDown() {
    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 1000,
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn);
  }

  void _handleSubmitted(String text) {
    if (messageController.text.isEmptyOrNull) {
      return;
    }
    messageController.clear();
    var message = MessageModel(
        message: text,
        time: DateFormat('HH:mm').format(DateTime.now()),
        username: deviceUsername,
        sent: true);
    context.read<MessagesBloc>().add(AddNewMessageEvent(messageModel: message));
    socket.emit(EVENTS.sendMessage, <String, dynamic>{
      "roomId": "1",
      "message": text,
      "username": message.username
    });
    context.read<MessagesBloc>().add(FetchMessageEvent());
    scrollDown();
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: BuildTextField(
                  hint: "Send a message",
                  inputType: TextInputType.multiline,
                  maxLines: null,
                  hintColor: kGrey00,
                  focusNode: focusNode,
                  fillColor: kGrey0,
                  textColor: kWhiteColor,
                  onChange: (val) {},
                  controller: messageController,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                child: IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: kWhiteColor,
                  ),
                  onPressed: () => _handleSubmitted(messageController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    var alignment = message.sent ? Alignment.centerRight : Alignment.centerLeft;
    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            message.sent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: message.sent ? kPrimaryColor : kGrey0,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: message.sent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: primaryTextStyle(color: kWhiteColor),
                ),
                8.height,
                Text(
                  message.time,
                  style: primaryTextStyle(size: 10, color: kGrey1),
                  textAlign: TextAlign.right,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: kGrey00,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: kWhiteColor,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              Column(
                children: [
                  Text(
                    connected ? "Connected" : "Disconnected",
                    style: TextStyle(
                        color: connected ? kWhiteColor : Colors.redAccent),
                  ),
                  (connected && !inChat)
                      ? Text(
                          lastOnline,
                          style: const TextStyle(color: kGrey2, fontSize: 10),
                        )
                      : const Offstage()
                ],
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
            icon: const Icon(
              Icons.arrow_back_ios_new_outlined,
            ),
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
            IconButton(
                onPressed: () {
                  socket.emit(EVENTS.poke, <String, dynamic>{
                    "username": deviceUsername,
                  });
                },
                icon: const Icon(Icons.notifications_active)),
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
                        // alignment: Alignment.bottomCenter,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => FocusScope.of(context).unfocus(),
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8.0),
                                itemCount: state.messages.length,
                                itemBuilder: (BuildContext context, int index) {
                                  // if (index == state.messages.length) {
                                  //   return Center(
                                  //     child: Container(
                                  //       child: Text(
                                  //         'Last Online: 2:52 AM',
                                  //         style: primaryTextStyle(
                                  //             size: 10, color: kGrey1),
                                  //       ),
                                  //       height: 25,
                                  //     ),
                                  //   );
                                  // }
                                  return _buildMessageBubble(
                                      state.messages[index]);
                                },
                              ),
                            ),
                          ),
                          _buildTextComposer(),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const SizedBox(
                                height: 50,
                              ),
                              SvgPicture.asset(
                                'assets/svgs/tasks.svg',
                                height: size.height * .20,
                                width: size.width,
                              ),
                              buildText(
                                  'No Messages',
                                  kWhiteColor,
                                  textBold,
                                  FontWeight.w600,
                                  TextAlign.center,
                                  TextOverflow.clip)
                            ],
                          ).expand(),
                          _buildTextComposer(),
                        ],
                      );
              }
              return Container();
            },
          ),
        ));
  }
}

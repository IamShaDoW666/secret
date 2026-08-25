import 'dart:async';
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
import 'package:task_manager_app/components/message_bubble.dart';
import 'package:task_manager_app/components/typing_indicator.dart';
import 'package:task_manager_app/components/widgets.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/message/presentation/bloc/messages_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/utils/color_palette.dart';
import 'package:task_manager_app/utils/common.dart';
import 'package:task_manager_app/utils/constants.dart';
import 'package:task_manager_app/utils/font_sizes.dart';
import 'package:task_manager_app/utils/logger.dart';
import 'package:throttling/throttling.dart';
import 'package:nanoid/nanoid.dart';

import '../../../utils/util.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late io.Socket socket;
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final thr = Throttling<void>(duration: const Duration(milliseconds: 2000));
  Timer? typingTimer;
  bool connected = false;
  bool inChat = false;
  bool typing = false;
  String lastOnline = '-';
  final String deviceUsername = getStringAsync(Constants.usernameKey);
  void connectSocket() {
    logger.d(io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({'username': deviceUsername})
        .build());
    socket = io.io(
        getBoolAsync(Constants.environment)
            ? Constants.livehost
            : getStringAsync(Constants.localhost),
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setQuery({'username': deviceUsername})
            .build());

    socket.connect();

    socket.onConnect((data) {
      setState(() {
        connected = true;
      });

      // New message event
      socket.on(EVENTS.newMessage, (data) {
        setState(() {
          typing = false;
          typingTimer?.cancel();
        });
        var message = MessageModel(
            id: data["id"] ?? nanoid(),
            status: "RECEIVED",
            message: data["message"],
            time: data["time"],
            username: data["username"]);
        context
            .read<MessagesBloc>()
            .add(AddNewMessageEvent(messageModel: message));
        socket.emit(EVENTS.readAck, <String, dynamic>{
          "messageId": message.id,
          "username": deviceUsername,
        });
      });

      socket.on(EVENTS.readAckServer, (data) {
        var messageId = data["id"];
        context.read<MessagesBloc>().add(ReadAckEvent(messageId: messageId));
      });

      socket.on(EVENTS.connections, (data) {
        logger.d(data);
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
      logger.d('messages: $messages');
      for (var message in messages) {
        if (message.username != deviceUsername) {
          context
              .read<MessagesBloc>()
              .add(AddNewMessageEvent(messageModel: message));
        }
      }
      socket.emit(EVENTS.downstream);
    });

    socket.on(EVENTS.typingServer, (data) {
      setState(() {
        typing = true;
        typingTimer?.cancel();
        _scrollDown();
      });
      typingTimer = Timer(const Duration(milliseconds: 2500), () {
        setState(() {
          typing = false;
        });
      });
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
          '${getBoolAsync(Constants.environment) ? Constants.livehost : getStringAsync(Constants.localhost)}/last-online?username=${getReciever(deviceUsername)}'),
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
        Future.delayed(const Duration(milliseconds: 300), () => _scrollDown());
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

  void _scrollDown() {
    Future.delayed(Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _handleSubmitted(String text) {
    if (messageController.text.isEmptyOrNull) {
      return;
    }
    messageController.clear();
    var message = MessageModel(
        id: nanoid(),
        message: text,
        status: "SENDING",
        time: DateTime.now().toString(),
        username: deviceUsername,
        sent: true);
    context.read<MessagesBloc>().add(AddNewMessageEvent(messageModel: message));
    socket.emitWithAck(EVENTS.sendMessage, <String, dynamic>{
      "roomId": "1",
      "message": jsonEncode(message),
      "username": message.username,
    }, ack: (data) {
      if (data != null) {
        // Update the message status to SENT
        message.status = "SENT";
        context
            .read<MessagesBloc>()
            .add(UpdateMessageEvent(messageModel: message));
      } else {
        // Handle error if needed
        logger.e("Error sending message: $data");
      }
    });
    context.read<MessagesBloc>().add(FetchMessageEvent());
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
                  onChange: (val) {
                    setState(() {});
                    thr.throttle(() {
                      socket.emit(EVENTS.typing);
                    });
                  },
                  controller: messageController,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: messageController.text.isEmptyOrNull
                          ? Tween<double>(begin: 0, end: 1).animate(anim)
                          : Tween<double>(begin: 0.75, end: 1).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: messageController.text.isEmptyOrNull
                        ? const Icon(
                            Icons.mic,
                            key: ValueKey(1),
                            color: kWhiteColor,
                          )
                        : const Icon(
                            Icons.send,
                            key: ValueKey(2),
                            color: kWhiteColor,
                          ),
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

              if (state is FetchMessagesSuccess) {
                if (state.messages.isNotEmpty) {
                  _scrollDown();
                }
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
                                itemCount: !typing
                                    ? state.messages.length
                                    : state.messages.length + 1,
                                itemBuilder: (BuildContext context, int index) {
                                  if (index == state.messages.length) {
                                    return TypingIndicator();
                                  }
                                  return MessageBubble(
                                      message: state.messages[index]);
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

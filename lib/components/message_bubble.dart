import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/message/data/local/model/message_model.dart';
import 'package:task_manager_app/utils/color_palette.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    var alignment = message.sent ? Alignment.centerRight : Alignment.centerLeft;
    DateTime utcTime = DateTime.parse(message.time);
    String formattedTime = DateFormat('h:mm a').format(utcTime.toLocal());
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
                  formattedTime,
                  style: primaryTextStyle(size: 10, color: kGrey1),
                  textAlign: TextAlign.right,
                ),
                message.sent ? getMessageStatus(message) : const Offstage(),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Icon getMessageStatus(MessageModel message) {
  if (message.status == "SENDING") {
    return const Icon(Icons.access_time, color: kGrey1, size: 12);
  }
  if (message.status == "SENT") {
    return const Icon(Icons.done, color: kGrey1, size: 12);
  }
  if (message.status == "RECEIVED") {
    return const Icon(Icons.done_all, color: kGrey1, size: 12);
  }
  if (message.status == "READ") {
    return const Icon(Icons.done_all,
        color: Color.fromARGB(170, 182, 142, 255), size: 12);
  }
  return const Icon(Icons.error, color: kRed, size: 12);
}

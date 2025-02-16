import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/firebase_api.dart';
import 'package:task_manager_app/tasks/presentation/pages/tasks_screen.dart';
import 'package:task_manager_app/utils/color_palette.dart';
import 'package:task_manager_app/utils/constants.dart';

class ChangeUserScreen extends StatelessWidget {
  const ChangeUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey00,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: kWhiteColor,
        scrolledUnderElevation: 0,
        title: const Text("Change user"),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const UserSelection(
            user: "Milan",
          ).expand(),
          const UserSelection(
            user: "Malu",
          ).expand(),
        ],
      ),
    );
  }
}

class UserSelection extends StatelessWidget {
  final String user;
  const UserSelection({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await setValue(Constants.usernameKey, user);
        await initToken();
        const TasksScreen()
            // ignore: use_build_context_synchronously
            .launch(duration: const Duration(milliseconds: 500), context);
      },
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.all(8),
        decoration: boxDecorationRoundedWithShadow(12,
            backgroundColor: user == "Milan" ? kPrimaryColor : kSecondaryColor),
        child: Center(
            child: Text(
          user,
          style: boldTextStyle(color: kWhiteColor, size: 64),
        )),
      ),
    ).paddingAll(18);
  }
}

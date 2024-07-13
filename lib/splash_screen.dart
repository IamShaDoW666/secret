import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/utils/constants.dart';
import 'components/widgets.dart';
import 'routes/pages.dart';
import 'utils/color_palette.dart';
import 'utils/font_sizes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    startTimer();
    super.initState();
  }

  startTimer() async {
    Future.delayed(const Duration(milliseconds: 3000), () {
      String user = getStringAsync(Constants.usernameKey);
      if (user.isNotEmpty) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Pages.home,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Pages.changeUser,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kPrimaryColor,
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 100,
            ),
            const SizedBox(
              height: 20,
            ),
            buildText('Task Manager', kWhiteColor, textBold, FontWeight.w600,
                TextAlign.center, TextOverflow.clip),
            const SizedBox(
              height: 10,
            ),
            buildText('Schedule your week with ease', kWhiteColor, textTiny,
                FontWeight.normal, TextAlign.center, TextOverflow.clip),
          ],
        )));
  }
}

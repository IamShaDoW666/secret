import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/utils/color_palette.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  TypingIndicatorState createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1, _dot2, _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _dot1 = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.33, curve: Curves.easeInOut)),
    );
    _dot2 = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.53, curve: Curves.easeInOut)),
    );
    _dot3 = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.73, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: kGrey0, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDot(_dot1.value),
                        _buildDot(_dot2.value),
                        _buildDot(_dot3.value),
                      ],
                    );
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildDot(double offsetY) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2.0),
    child: Transform.translate(
      offset: Offset(0, offsetY),
      child: const CircleAvatar(
        radius: 4,
        backgroundColor: kGrey00,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText; // Add a field for the title
  final Widget button1;
  final Widget button2;
  const MyAppBar({
    super.key,
    required this.button1,
    required this.button2,
    required this.titleText,
  }); // Constructor with titleText

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        titleText,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        // Dark mode toggle
        button1,
        button2,

        // Settings page navigation
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight); // AppBar height
}

import 'package:flutter/material.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(2);
ValueNotifier<bool> isDarkThemeNotifier = ValueNotifier(true);
ValueNotifier<dynamic> selectedAddPageNotifier = ValueNotifier(null);
// 'mn' | 'en' | 'jp'
ValueNotifier<String> languageNotifier = ValueNotifier('mn');

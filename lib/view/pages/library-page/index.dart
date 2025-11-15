// lib/view/pages/library/index.dart
// Fixed version with proper tab lifecycle management

import 'package:flutter/material.dart';
import 'package:ivo/components/buttons/profile_nav_button.dart';
import 'package:ivo/components/buttons/settings_nav_button.dart';
import 'package:ivo/components/common/app_bar.dart';
import 'package:ivo/components/flashcard/flashcard-list.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(
          button1: SettingsNavButton(),
          button2: ProfileNavButton(),
          titleText: "Миний сан",
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Custom tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  _buildTab('Нийтлэл', 0),
                  _buildTab('Флаш карт', 1),
                  _buildTab('Аудио карт', 2),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  Center(child: Text("ok")),
                  FlashcardList(),
                  Center(child: Placeholder()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

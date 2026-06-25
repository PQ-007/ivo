import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:ivo/components/buttons/profile_nav_button.dart';
import 'package:ivo/components/buttons/settings_nav_button.dart';
import 'package:ivo/components/common/app_bar.dart';
import 'package:ivo/view/pages/study/deck_list.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

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
            Expanded(
              child: FTabs(
                initialIndex: 1,
                onPress: (index) {},
                children: const [
                  FTabEntry(label: Text('Нийтлэл'), child: Text("ok")),
                  FTabEntry(label: Text('Флаш карт'), child: DeckListView()),
                  FTabEntry(label: Text('Аудио карт'), child: Placeholder()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

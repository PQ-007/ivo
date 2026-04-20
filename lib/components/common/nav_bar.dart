import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/data/notifiers.dart';
import 'package:ivo/view/pages/add-page/index.dart';

class MyNavbar extends StatelessWidget {
  const MyNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, index, child) {
        return FBottomNavigationBar(
          index: index,
          onChange: (newIndex) {
            // Update the global page notifier
            selectedPageNotifier.value = newIndex;

            // If navigating to the add page (index 2), show the bottom sheet
            if (newIndex == 2) {
              _showAddSelectionBottomSheet(context);
            } else {
              // Reset add page selection when navigating away
              selectedAddPageNotifier.value = null;
            }
          },
          children: [
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.house),
              label: Text(t('nav_home')),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.telescope),
              label: Text(t('nav_articles')),
            ),
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () {
                selectedPageNotifier.value = 2;
              },
              child: Icon(
                FIcons.blocks,
                size: 32,
                color: Theme.of(context).iconTheme.color,
              ),
            ),

            FBottomNavigationBarItem(
              icon: const Icon(FIcons.chartBar),
              label: Text(t('nav_stats')),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.libraryBig),
              label: Text(t('nav_library')),
            ),
          ],
        );
      },
    );
  }
}

void _showAddSelectionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Шинэ үүсгэх',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.style),
              title: Text(t('add_deck_title')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeckPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Хавтас'),
              onTap: () {
                Navigator.pop(context);
                selectedAddPageNotifier.value = 'Folder';
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Плейлист'),
              onTap: () {
                Navigator.pop(context);
                selectedAddPageNotifier.value = 'Playlist';
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

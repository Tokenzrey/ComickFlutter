import 'package:flutter/material.dart';

class MyFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const MyFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      // Notch agar FAB terlihat 'tertancap'
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: Colors.black,
      child: SizedBox(
        height: 60.0, // Tinggi BottomAppBar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Ikon pertama (misalnya Home)
            IconButton(
              icon: Icon(
                Icons.home,
                color: (selectedIndex == 0) ? Colors.white : Colors.grey,
              ),
              onPressed: () => onItemTapped(0),
            ),

            // Ikon kedua (misalnya Clipboard)
            IconButton(
              icon: Icon(
                Icons.list_alt,
                color: (selectedIndex == 1) ? Colors.white : Colors.grey,
              ),
              onPressed: () => onItemTapped(1),
            ),

            // Spacer di tengah untuk area FAB
            const SizedBox(width: 48.0),

            // Ikon ketiga (misalnya Chart)
            IconButton(
              icon: Icon(
                Icons.show_chart,
                color: (selectedIndex == 2) ? Colors.white : Colors.grey,
              ),
              onPressed: () => onItemTapped(2),
            ),

            // Ikon keempat (misalnya Profile)
            IconButton(
              icon: Icon(
                Icons.person,
                color: (selectedIndex == 3) ? Colors.white : Colors.grey,
              ),
              onPressed: () => onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}

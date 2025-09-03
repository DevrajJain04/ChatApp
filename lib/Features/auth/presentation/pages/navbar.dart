import 'package:flutter/material.dart';
import 'package:yappsters/Features/messaging/Presentation/pages/all_chats_screen.dart';
import 'package:yappsters/Features/messaging/Presentation/pages/profile_page.dart';

import '../../../../core/constants/enums.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => NavBarState();
}

class NavBarState extends State<NavBar> {
  PageController pc = PageController(initialPage: 0);
  final routes = <Widget>[
    const AllChatScreen(),  ProfilePage(), // callpage
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pc,
        onPageChanged: (value) {
          setState(() {
            currentPageIndex = value;
          });
        },
        children: routes,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.blue[200],
        ),
        child: NavigationBar(
          elevation: 10,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat), label: 'Chats'),
            // NavigationDestination(icon: Icon(Icons.call), label: 'Calls'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedIndex: currentPageIndex,
          onDestinationSelected: (index) {
            // currentPageIndex = index;
            pc.animateToPage(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeIn,
            );
          },
        ),
      ),
    );
  }
}

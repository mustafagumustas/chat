import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'main.dart'; // To navigate back to the Chat page if needed.

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Disables system back actions (including swipe back)
      onWillPop: () async => false,
      child: Scaffold(
        // Include a drawer so that the selection button can open it.
        drawer: Container(
          width: 250,
          child: Drawer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Profile is highlighted on this page
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      minLeadingWidth: 30,
                      horizontalTitleGap: 20,
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFF4B3B2F),
                      ),
                      title: const Text(
                        'Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B3B2F),
                        ),
                      ),
                      selected: true,
                      selectedTileColor: Colors.grey[300],
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    // Chat ListTile that navigates to the chat screen.
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      minLeadingWidth: 30,
                      horizontalTitleGap: 20,
                      leading: const Icon(
                        Icons.chat,
                        color: Color(0xFF4B3B2F),
                      ),
                      title: const Text(
                        'Chat',
                        style: TextStyle(color: Color(0xFF4B3B2F)),
                      ),
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MyHomePage(title: 'Chat App'),
                          ),
                        );
                      },
                    ),
                    // Calendar ListTile
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      minLeadingWidth: 30,
                      horizontalTitleGap: 20,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF4B3B2F),
                      ),
                      title: const Text(
                        'Calendar',
                        style: TextStyle(color: Color(0xFF4B3B2F)),
                      ),
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CalendarPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Prevent the default back arrow from being displayed.
          automaticallyImplyLeading: false,
          // Add the same "Selection" (menu) button as in the Chat page.
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu,
                color: Color(0xFF4B3B2F),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            "Profile",
            style: TextStyle(color: Color(0xFF4B3B2F)),
          ),
        ),
        backgroundColor: const Color(0xFFFFF9F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A placeholder for profile picture.
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF4B3B2F),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                "John Doe",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B3B2F),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "johndoe@example.com",
                style: TextStyle(fontSize: 16, color: Color(0xFF4B3B2F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

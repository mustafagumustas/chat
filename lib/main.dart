import 'dart:convert'; // Required for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'calendar_page.dart'; // Import the new CalendarPage file
import 'profile_page.dart'; // Import the Profile page
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
import 'dart:io';
 
void main() {
  // Add SSL security exceptions for development/testing
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

// Custom HTTP overrides for debugging SSL issues
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        dev.log('SSL Certificate Issue - Host: $host, Port: $port');
        return false; // Still reject bad certificates, but log them
      };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        fontFamily: 'CocomatPro',
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
          ),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('tr', ''), // Turkish
        // Add other locales if needed
      ],
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();

  // Added ScrollController for ListView auto-scrolling
  final ScrollController _scrollController = ScrollController();

  String? _userId;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register the observer
    _initializeUserId();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_sessionId == null) {
        _startSession();
      }
    } else if (state == AppLifecycleState.detached) {
      _endSession();
    }
  }

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    dev.log('Fetched user_id: $_userId'); // Debugging line

    if (_userId == null) {
      dev.log('User ID not found, prompting for user input');
      _promptForUserId();
    } else {
      _startSession();
    }
  }

  Future<void> _startSession() async {
    if (_userId == null) return;

    dev.log('Attempting to start session for user: $_userId');
    final url = Uri.parse('https://api.savantai.net/start_session');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"user_id": _userId}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _sessionId = decoded['session_id'];
        });
        dev.log('Session started with ID: $_sessionId');
      } else {
        dev.log(
            'Error starting session: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      dev.log('Session start error: $e');
    }
  }

  Future<void> _endSession() async {
    if (_userId == null || _sessionId == null) return;

    final url = Uri.parse('https://api.savantai.net/end_session');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"user_id": _userId, "session_id": _sessionId}),
      );

      if (response.statusCode == 200) {
        dev.log('Session ended successfully');
        _sessionId = null;
      } else {
        dev.log(
            'Error ending session: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      dev.log('Session end error: $e');
    }
  }

  Future<void> _promptForUserId() async {
    final userId = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter User ID'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'User ID'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (userId != null && userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      setState(() {
        _userId = userId;
      });
      await _startSession(); // Start session immediately after setting user ID
    }
  }

  Future<void> _handleSend(String text) async {
    if (text.isNotEmpty && _userId != null) {
      _textController.clear();

      setState(() {
        _messages.add(
            ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      });
      _scrollToBottom();

      final url = Uri.parse('https://api.savantai.net/process');
      dev.log('Sending request to: $url');

      try {
        // Check if we have a session ID
        if (_sessionId == null) {
          await _startSession(); // Try to start a session if we don't have one

          // Verify that session was successfully created
          if (_sessionId == null) {
            setState(() {
              _messages.add(ChatMessage(
                  text: 'Unable to start a session. Please try again later.',
                  isUser: false,
                  timestamp: DateTime.now()));
            });
            _scrollToBottom();
            return; // Exit early if we couldn't create a session
          }
        }

        // Construct the payload first
        final requestPayload = {
          "user_id": _userId,
          "session_id": _sessionId,
          "text": text,
          "client_time": DateTime.now().toIso8601String(),
          "timezone": DateTime.now().timeZoneName
        };

        // Log the exact payload
        dev.log('Request payload: ${jsonEncode(requestPayload)}');

        // Send the payload
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode(requestPayload), // Use the same payload object
        );

        dev.log('Response status: ${response.statusCode}');
        dev.log('Response headers: ${response.headers}');
        dev.log('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          setState(() {
            _messages.add(ChatMessage(
                text: decoded['text'],
                isUser: false,
                timestamp: DateTime.now()));
          });
          _scrollToBottom();
        } else {
          dev.log('Error response: ${response.body}');
          setState(() {
            _messages.add(ChatMessage(
                text: 'Error: ${response.statusCode} - ${response.body}',
                isUser: false,
                timestamp: DateTime.now()));
          });
          _scrollToBottom();
        }
      } catch (e, stackTrace) {
        dev.log('Network error: $e');
        dev.log('Stack trace: $stackTrace');
        setState(() {
          _messages.add(ChatMessage(
              text: 'Connection error: $e',
              isUser: false,
              timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }

      _textFieldFocus.requestFocus();
    }
  }

  // Function to scroll the ListView to the bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrapping with PopScope disables the swipe/back gesture.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9F0),
        // Add a Drawer that contains the sections menu.
        drawer: SizedBox(
          width: 250, // Thinner section width.
          child: Drawer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 20.0), // Top padding from screen edge.
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Navigate to Profile if not active.
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      minLeadingWidth: 30,
                      horizontalTitleGap: 20,
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFF6D4C41),
                      ),
                      title: const Text('Profile'),
                      selected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
                        );
                      },
                    ),
                    // Chat tile is active, so simply close the drawer.
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
                    // Navigate to Calendar if not active.
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      minLeadingWidth: 30,
                      horizontalTitleGap: 20,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF6D4C41),
                      ),
                      title: const Text(
                        'Calendar',
                        style: TextStyle(color: Color(0xFF6D4C41)),
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
          automaticallyImplyLeading: false,
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
            'Chat App',
            style: TextStyle(color: Color(0xFF4B3B2F)),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.copy,
                color: Color(0xFF4B3B2F),
              ),
              onPressed: () {
                // Format all messages into the required JSON structure
                final formattedChat = _messages
                    .map((msg) => {
                          "role": msg.isUser ? "user" : "assistant",
                          "content": msg.text
                        })
                    .toList();

                // Convert to a properly formatted JSON string
                final jsonStr = '''[
    ${formattedChat.map((m) => '''    {
        "role": "${m['role']}",
        "content": """${m['content']}"""
    }''').join(',\n')}
]''';

                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: jsonStr));

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation copied in JSON format'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(message: message);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 4, 8, 40),
              child: Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (KeyEvent event) {
                        // This helps prevent keyboard event inconsistencies
                        if (event is KeyUpEvent &&
                            event.logicalKey == LogicalKeyboardKey.backspace) {
                          // Handle backspace key up event
                          return;
                        }
                      },
                      child: TextField(
                        controller: _textController,
                        focusNode: _textFieldFocus,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                        onSubmitted: (text) => _handleSend(text),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_upward, // Send icon is an up arrow.
                        color: Color(0xFF6D4C41),
                        size: 32.0,
                      ),
                      onPressed: () {
                        _handleSend(_textController.text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove the observer
    _endSession(); // End the session when the app is closed
    _textController.dispose();
    _textFieldFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage(
      {required this.text, required this.isUser, required this.timestamp});
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    return Container(
      key: ValueKey('messageBubble_${message.text.hashCode}'),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        key: const Key('messageBubble_innerContainer'),
        margin: isUser
            ? const EdgeInsets.only(left: 40)
            : const EdgeInsets.only(right: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              message.text,
              key: const Key('messageBubble_text'),
              style: TextStyle(color: isUser ? Colors.white : Colors.black),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

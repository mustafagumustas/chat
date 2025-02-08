import 'dart:convert'; // Required for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'calendar_page.dart'; // Import the new CalendarPage file

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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
      // Localization settings: include these if you are targeting multiple locales.
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

class _MyHomePageState extends State<MyHomePage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();

  // Added ScrollController for ListView auto-scrolling
  final ScrollController _scrollController = ScrollController();

  // Add initState to initialize the chat as soon as the app opens.
  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // New function to send an init signal to the backend.
  Future<void> _initializeChat() async {
    final url = Uri.parse('http://127.0.0.1:8000/init');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: decoded['text'], isUser: false));
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add(ChatMessage(
              text: 'Error initializing chat: ${response.statusCode}',
              isUser: false));
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(
            ChatMessage(text: 'Error initializing chat: $e', isUser: false));
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleSend(String text) async {
    if (text.isNotEmpty) {
      // Immediately clear the text field.
      _textController.clear();

      // Add the user's message to the chat list.
      setState(() {
        _messages.add(ChatMessage(text: text, isUser: true));
      });
      _scrollToBottom();

      final url = Uri.parse('http://127.0.0.1:8000/process');

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"text": text}),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          setState(() {
            _messages.add(ChatMessage(text: decoded['text'], isUser: false));
          });
          _scrollToBottom();
        } else {
          setState(() {
            _messages.add(ChatMessage(
                text: 'Error: ${response.statusCode}', isUser: false));
          });
          _scrollToBottom();
        }
      } catch (e) {
        setState(() {
          _messages.add(ChatMessage(text: 'Error: $e', isUser: false));
        });
        _scrollToBottom();
      }

      // Bring the focus back to the text field.
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),
      // Add a Drawer that contains the sections menu.
      drawer: Container(
        width: 250, // Thinner section width.
        child: Drawer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 20.0), // Top padding from screen edge.
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
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
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Add functionality to navigate to the profile page.
                    },
                  ),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0),
                    minLeadingWidth: 30,
                    horizontalTitleGap: 20,
                    leading: const Icon(
                      Icons.chat,
                      color: Color(0xFF6D4C41),
                    ),
                    title: const Text('Chat'),
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
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Remove AppBar background.
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Color(0xFF6D4C41),
            ),
            onPressed: () {
              Scaffold.of(context)
                  .openDrawer(); // Open the Drawer when pressed.
            },
          ),
        ),
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today, // Calendar icon on the right.
              color: Color(0xFF6D4C41),
              size: 32.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarPage()),
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
                return Container(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: message.isUser
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          child: Text(message.text),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 4, 8, 40),
            child: Row(
              children: [
                Expanded(
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
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFieldFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

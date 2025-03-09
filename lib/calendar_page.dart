import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final PageController _pageController;
  int currentPage = 0;
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);

    // Listen to the controller to update which page is selected.
    _pageController.addListener(() {
      final page = _pageController.page;
      if (page != null) {
        setState(() {
          currentPage = page.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with a transparent background and custom icon color.
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4B3B2F)),
      ),
      backgroundColor: const Color(0xFFFFF9F0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Weekly Schedule',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B3B2F),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 150.0,
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: currentPage == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: const Color(0xFF4B3B2F),
                            ),
                          ),
                          if (currentPage == index)
                            Container(
                              margin: const EdgeInsets.only(top: 4.0),
                              width: 40.0,
                              height: 2.0,
                              color: Colors.lightGreen,
                            ),
                          const SizedBox(height: 10),
                          const Expanded(
                            child: Text(
                              'Daily content goes here...',
                              style: TextStyle(color: Color(0xFF4B3B2F)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

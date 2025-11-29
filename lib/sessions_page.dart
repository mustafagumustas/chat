import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class SessionResumeData {
  final String sessionId;
  final List<Map<String, dynamic>> history;

  SessionResumeData({required this.sessionId, required this.history});
}

class SessionInfo {
  final String sessionId;
  final DateTime? startedAt;
  final DateTime? lastActivity;
  final int totalTurns;
  final List<Map<String, dynamic>> history;

  SessionInfo({
    required this.sessionId,
    required this.startedAt,
    required this.lastActivity,
    required this.totalTurns,
    required this.history,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    final historyEntries = (json['history'] as List<dynamic>? ?? [])
        .map((entry) => {
              'role': entry['role'] ?? '',
              'content': entry['content'] ?? '',
              'timestamp': entry['timestamp'],
            })
        .toList();

    return SessionInfo(
      sessionId: json['session_id'] ?? '',
      startedAt: _parseDate(json['started_at']),
      lastActivity: _parseDate(json['last_activity']),
      totalTurns: json['total_turns'] is int
          ? json['total_turns'] as int
          : int.tryParse(json['total_turns']?.toString() ?? '') ?? 0,
      history: historyEntries,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class SessionsDrawerSection extends StatefulWidget {
  final ValueChanged<SessionResumeData> onSessionSelected;

  const SessionsDrawerSection({
    super.key,
    required this.onSessionSelected,
  });

  @override
  State<SessionsDrawerSection> createState() => _SessionsDrawerSectionState();
}

class _SessionsDrawerSectionState extends State<SessionsDrawerSection> {
  late Future<List<SessionInfo>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _fetchSessions();
  }

  Future<List<SessionInfo>> _fetchSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null || userId.isEmpty) {
      return [];
    }

    final url = apiUri('sessions/$userId');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load sessions (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .map<SessionInfo>(
            (entry) => SessionInfo.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refreshSessions() async {
    setState(() {
      _sessionsFuture = _fetchSessions();
    });
    await _sessionsFuture;
  }

  void _handleTap(SessionInfo session) {
    final historyCopy = session.history
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    widget.onSessionSelected(
      SessionResumeData(sessionId: session.sessionId, history: historyCopy),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<SessionInfo>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Unable to load sessions',
                    style: const TextStyle(color: Color(0xFF4B3B2F)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF6D4C41)),
                  onPressed: _refreshSessions,
                ),
              ],
            ),
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No recent sessions',
              style: TextStyle(color: Color(0xFF6D4C41)),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              dense: true,
              title: Text(
                _formatDateTime(session.startedAt),
                style: const TextStyle(
                  color: Color(0xFF4B3B2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Last: ${_formatDateTime(session.lastActivity)} • ${session.totalTurns} turns',
                style: const TextStyle(color: Color(0xFF6D4C41)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Color(0xFF6D4C41)),
              onTap: () => _handleTap(session),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) {
      return 'Unknown';
    }
    final local = dt.toLocal();
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date • $time';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B3B2F),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF6D4C41)),
                tooltip: 'Refresh',
                onPressed: _refreshSessions,
              )
            ],
          ),
          _buildContent(),
        ],
      ),
    );
  }
}

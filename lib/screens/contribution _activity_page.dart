import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:simple_heatmap_calendar/simple_heatmap_calendar.dart';

class ContributionActivityPage extends StatefulWidget {
  final String username;
  final bool showAppBar;

  const ContributionActivityPage({
    Key? key,
    required this.username,
    this.showAppBar = false,
  }) : super(key: key);

  @override
  _ContributionActivityPageState createState() =>
      _ContributionActivityPageState();
}

class _ContributionActivityPageState extends State<ContributionActivityPage> {
  Map<DateTime, int> _contributionData = {};
  bool _isLoading = true;
  String? _error;

  String? _joinDate;
  String? _firstRepoName;
  String? _firstRepoCreatedAt;
  List<Map<String, String>> _recentCommits = [];

  final int _selectedYear = 2025; // 🔒 Hardcoded to 2025

  @override
  void initState() {
    super.initState();
    _fetchContributions();
  }

  Future<void> _fetchContributions() async {
    setState(() {
      _isLoading = true;
      _contributionData.clear();
      _error = null;
    });

    try {
      final eventsUrl =
          'https://api.github.com/users/${widget.username}/events/public';
      final userUrl = 'https://api.github.com/users/${widget.username}';
      final reposUrl =
          'https://api.github.com/users/${widget.username}/repos?sort=created&direction=asc';

      final responses = await Future.wait([
        http.get(Uri.parse(eventsUrl)),
        http.get(Uri.parse(userUrl)),
        http.get(Uri.parse(reposUrl)),
      ]);

      if (responses.any((res) => res.statusCode != 200)) {
        setState(() {
          _error = 'Error fetching data. Please try again later.';
          _isLoading = false;
        });
        return;
      }

      final events = json.decode(responses[0].body) as List;
      final userData = json.decode(responses[1].body);
      final repos = json.decode(responses[2].body) as List;

      Map<DateTime, int> dateCount = {};
      List<Map<String, String>> commits = [];

      final createdAt = userData['created_at'];
      if (createdAt != null) {
        final joinDateParsed = DateTime.parse(createdAt).toLocal();
        _joinDate = joinDateParsed.toString().split(' ')[0];
      }

      for (var event in events) {
        final type = event['type'];
        final createdAt = DateTime.parse(event['created_at']).toLocal();

        if (createdAt.year == _selectedYear) {
          final cleanDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
          dateCount.update(cleanDate, (value) => value + 1, ifAbsent: () => 1);

          if (type == 'PushEvent') {
            final repoName = event['repo']['name'];
            commits.add({
              'repo': repoName,
              'date': createdAt.toString(),
            });
          }
        }
      }

      final firstRepo =
      repos.firstWhere((repo) => !repo['private'], orElse: () => null);

      setState(() {
        _contributionData = dateCount;
        _recentCommits = commits.take(5).toList();
        _firstRepoName = firstRepo?['name'];
        _firstRepoCreatedAt = firstRepo?['created_at'] != null
            ? DateTime.parse(firstRepo['created_at']).toLocal().toString().split(' ')[0]
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load contributions. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startDate = DateTime(_selectedYear, 1, 1);
    final DateTime endDate = DateTime(_selectedYear, 12, 31);

    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
      child: Text(_error!, style: const TextStyle(color: Colors.red)),
    )
        : SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔲 Contribution Graph
          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: HeatmapCalendar<num>(
                startDate: startDate,
                endedDate: endDate,
                colorMap: {
                  1: Colors.green[100]!,
                  3: Colors.green[300]!,
                  5: Colors.green[500]!,
                  7: Colors.green[700]!,
                  10: Colors.green[900]!,
                },
                selectedMap: _contributionData,
                cellSize: const Size.square(16.0),
                colorTipCellSize: const Size.square(12.0),
                style: const HeatmapCalendarStyle.defaults(
                  cellValueFontSize: 6.0,
                  cellRadius: BorderRadius.all(Radius.circular(4.0)),
                  weekLabelValueFontSize: 12.0,
                  monthLabelFontSize: 12.0,
                ),
                layoutParameters: const HeatmapLayoutParameters.defaults(
                  monthLabelPosition: CalendarMonthLabelPosition.top,
                  weekLabelPosition: CalendarWeekLabelPosition.right,
                  colorTipPosition: CalendarColorTipPosition.bottom,
                ),
              ),
            ),
          ),

          /// 📅 Join Date
          if (_joinDate != null)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Joined GitHub on $_joinDate'),
              ),
            ),

          /// 📌 First Repo Info
          if (_firstRepoName != null)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.folder),
                title: Text('First Repository: $_firstRepoName'),
                subtitle: _firstRepoCreatedAt != null
                    ? Text('Created on $_firstRepoCreatedAt')
                    : null,
              ),
            ),

          /// 🔨 Recent Commits
          if (_recentCommits.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('🔨 Recent Commits:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ..._recentCommits.map(
                  (commit) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.code, color: Colors.green),
                  title: Text(commit['repo'] ?? ''),
                  subtitle: Text(commit['date'] ?? ''),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return widget.showAppBar
        ? Scaffold(
        appBar: AppBar(title: Text('${widget.username} Activity')),
        body: content)
        : content;
  }
}

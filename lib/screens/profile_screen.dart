import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'repository_page.dart';
import 'contribution _activity_page.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({required this.username});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? profileData;
  List<dynamic> contributionEvents = [];
  List<dynamic> repoData = [];

  bool isLoading = true;
  String? error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Only 1 tab for activity
    _fetchProfile(widget.username);
  }

  Future<void> _fetchProfile(String username) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final profileRes = await http.get(Uri.parse('https://api.github.com/users/$username'));
      final eventsRes = await http.get(Uri.parse('https://api.github.com/users/$username/events'));
      final reposRes = await http.get(Uri.parse('https://api.github.com/users/$username/repos?per_page=100'));

      if (profileRes.statusCode == 200 &&
          eventsRes.statusCode == 200 &&
          reposRes.statusCode == 200) {
        setState(() {
          profileData = json.decode(profileRes.body);
          contributionEvents = json.decode(eventsRes.body);
          repoData = json.decode(reposRes.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'User not found or API error';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('GitHub Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('GitHub Profile')),
        body: Center(child: Text(error!, style: TextStyle(color: Colors.red))),
      );
    }

    final user = profileData!;
    final joinedDate = user['created_at']?.split('T')?.first;

    return Scaffold(
      appBar: AppBar(title: Text(user['login'])),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user['avatar_url']),
                  ),
                  SizedBox(height: 16),
                  Text(user['name'] ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('@${user['login']}', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 10),
                  if (user['bio'] != null)
                    Text(user['bio'], textAlign: TextAlign.center),
                  SizedBox(height: 10),
                  if (user['location'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 4),
                        Text(user['location']),
                      ],
                    ),
                  if (user['email'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 16),
                        SizedBox(width: 4),
                        Text(user['email']),
                      ],
                    ),
                  if (user['blog'] != null && user['blog'].toString().isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link, size: 16),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () async {
                            final url = user['blog'].toString().startsWith('http')
                                ? user['blog']
                                : 'https://${user['blog']}';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                          child: Text(
                            user['blog'],
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('Repos', user['public_repos'].toString()),
                      _buildStat('Followers', user['followers'].toString()),
                      _buildStat('Following', user['following'].toString()),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (joinedDate != null)
                    Text('Joined GitHub on $joinedDate',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RepositoriesPage(username: widget.username),
                        ),
                      );
                    },
                    icon: Icon(Icons.folder_open),
                    label: Text("View All Repositories"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 30),
                  // 🔘 Tab bar for activity
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    tabs: [
                      Tab(text: 'Contribution Activity'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🔁 Contribution activity tab
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContributionActivityView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String count) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
  Widget _buildContributionActivityView() {
    return ContributionActivityPage(
      username: widget.username,
      showAppBar: false, // disables the app bar
    );
  }
}

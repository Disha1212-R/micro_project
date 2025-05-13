import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({required this.username});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  List<dynamic> repoData = [];
  List<dynamic> filteredRepos = [];
  bool isLoading = true;
  String? error;

  final TextEditingController _searchController = TextEditingController();
  String selectedType = 'All';
  String selectedSort = 'Name';

  @override
  void initState() {
    super.initState();
    _fetchData(widget.username);
    _searchController.addListener(_filterRepos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData(String username) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final profileRes = await http.get(Uri.parse('https://api.github.com/users/$username'));
      final repoRes = await http.get(Uri.parse('https://api.github.com/users/$username/repos'));

      if (profileRes.statusCode == 200 && repoRes.statusCode == 200) {
        setState(() {
          profileData = json.decode(profileRes.body);
          repoData = json.decode(repoRes.body);
          _filterRepos(); // Apply filter and sort
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

  void _filterRepos() {
    String query = _searchController.text.toLowerCase();
    List<dynamic> temp = repoData.where((repo) {
      bool matchesSearch = repo['name'].toLowerCase().contains(query);
      bool matchesType = selectedType == 'All' ||
          (selectedType == 'Forks' && repo['fork'] == true) ||
          (selectedType == 'Sources' && repo['fork'] == false);
      return matchesSearch && matchesType;
    }).toList();

    if (selectedSort == 'Name') {
      temp.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (selectedSort == 'Updated') {
      temp.sort((a, b) => b['updated_at'].compareTo(a['updated_at']));
    } else if (selectedSort == 'Stars') {
      temp.sort((a, b) => (b['stargazers_count'] ?? 0).compareTo(a['stargazers_count'] ?? 0));
    }

    setState(() {
      filteredRepos = temp;
    });
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

    return Scaffold(
      appBar: AppBar(title: Text(user['login'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user['avatar_url']),
            ),
            SizedBox(height: 16),
            Text(user['name'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('@${user['login']}', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 10),
            if (user['bio'] != null) Text(user['bio'], textAlign: TextAlign.center),
            SizedBox(height: 10),

            // Social Info Block
            Column(
              children: [
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
              ],
            ),

            SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Repos', user['public_repos'].toString()),
                _buildStat('Followers', user['followers'].toString()),
                _buildStat('Following', user['following'].toString()),
              ],
            ),

            SizedBox(height: 20),

            // Follow Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Follow functionality not implemented')),
                );
              },
              icon: Icon(Icons.person_add_alt_1),
              label: Text('Follow'),
            ),

            SizedBox(height: 20),

            // Search & Filters
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Repositories',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    items: ['All', 'Forks', 'Sources']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      selectedType = val!;
                      _filterRepos();
                    },
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    items: ['Name', 'Updated', 'Stars']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      selectedSort = val!;
                      _filterRepos();
                    },
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Public Repositories (${filteredRepos.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredRepos.length,
              itemBuilder: (context, index) => _buildRepoCard(filteredRepos[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String count) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildRepoCard(dynamic repo) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(repo['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(repo['description'] ?? 'No description'),
            SizedBox(height: 4),
            Text('Updated: ${repo['updated_at'].split('T')[0]}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: Colors.amber),
            SizedBox(width: 4),
            Text('${repo['stargazers_count'] ?? 0}'),
          ],
        ),
        onTap: () async {
          final url = repo['html_url'];
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        },
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'repositoryview_page.dart';

class RepositoriesPage extends StatefulWidget {
  final String username;

  const RepositoriesPage({required this.username});

  @override
  State<RepositoriesPage> createState() => _RepositoriesPageState();
}

class _RepositoriesPageState extends State<RepositoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedType = 'All';
  String selectedSort = 'Name';

  List<dynamic> allRepos = [];
  List<dynamic> filteredRepos = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRepos);
    fetchRepositories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchRepositories() async {
    final url =
        'https://api.github.com/users/${widget.username}/repos?per_page=100';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          allRepos = data;
          isLoading = false;
        });
        _filterRepos(); // ✅ Call after setting data
      } else {
        setState(() {
          error =
          'Failed to fetch repositories. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _filterRepos() {
    final query = _searchController.text.toLowerCase();

    List<dynamic> temp = allRepos.where((repo) {
      final name = repo['name']?.toString().toLowerCase() ?? '';
      final isFork = repo['fork'] ?? false;
      bool matchesSearch = name.contains(query);
      bool matchesType = selectedType == 'All' ||
          (selectedType == 'Forks' && isFork) ||
          (selectedType == 'Sources' && !isFork);
      return matchesSearch && matchesType;
    }).toList();

    // Sorting
    if (selectedSort == 'Name') {
      temp.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (selectedSort == 'Updated') {
      temp.sort((a, b) {
        final aDate = DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate); // descending
      });
    } else if (selectedSort == 'Stars') {
      temp.sort((a, b) =>
          (b['stargazers_count'] ?? 0).compareTo(a['stargazers_count'] ?? 0));
    }

    setState(() {
      filteredRepos = temp;
    });
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat.yMMMd().format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.username}'s Repositories")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
          child: Text(error!, style: TextStyle(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Repositories',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    items: ['All', 'Forks', 'Sources']
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      selectedType = val!;
                      _filterRepos();
                    },
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    items: ['Name', 'Updated', 'Stars']
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      selectedSort = val!;
                      _filterRepos();
                    },
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredRepos.length,
                itemBuilder: (context, index) {
                  final repo = filteredRepos[index];
                  final formattedDate =
                  formatDate(repo['updated_at']);
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(repo['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              repo['description'] ??
                                  'No description available',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4),
                          Text('Updated: $formattedDate'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('${repo['stargazers_count'] ?? 0}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RepositoryDetailPage(
                                  owner: repo['owner']['login'],
                                  repo: repo['name'],
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

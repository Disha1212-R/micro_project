import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class RepositoryDetailPage extends StatefulWidget {
  final String owner;
  final String repo;

  const RepositoryDetailPage({
    Key? key,
    required this.owner,
    required this.repo,
  }) : super(key: key);

  @override
  _RepositoryDetailPageState createState() => _RepositoryDetailPageState();
}

class _RepositoryDetailPageState extends State<RepositoryDetailPage> {
  Map<String, dynamic>? repoData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchRepositoryDetails();
  }

  Future<void> fetchRepositoryDetails() async {
    final url = 'https://api.github.com/repos/${widget.owner}/${widget.repo}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          repoData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load repository data.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.owner}/${widget.repo}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
          : repoData == null
          ? const Center(child: Text("No data found."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTitleCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildMetaCard(),
            const SizedBox(height: 24),
            _buildGitHubButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repoData!['full_name'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              repoData!['description'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildIconStat(Icons.star, '${repoData!['stargazers_count']}', 'Stars'),
            _buildIconStat(Icons.call_split, '${repoData!['forks_count']}', 'Forks'),
            _buildIconStat(Icons.visibility, repoData!['visibility'], 'Visibility'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetaRow(Icons.code, 'Language', repoData!['language'] ?? 'N/A'),
            const Divider(),
            _buildMetaRow(Icons.update, 'Updated',
                repoData!['updated_at']?.split('T')?.first ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Text('$label:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildIconStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blueAccent),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGitHubButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final String repoUrl = 'https://github.com/${widget.owner}/${widget.repo}';
        final Uri url = Uri.parse(repoUrl);

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $repoUrl';
        }
      },
      icon: const Icon(Icons.open_in_new),
      label: const Text('Open in GitHub'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }}

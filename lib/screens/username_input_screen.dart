import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/custom_text_field.dart';
import '../screens/profile_screen.dart';

class UsernameInputScreen extends StatefulWidget {
  @override
  _UsernameInputScreenState createState() => _UsernameInputScreenState();
}

class _UsernameInputScreenState extends State<UsernameInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
  }

  Future<void> _loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('github_username');
    if (savedUsername != null && savedUsername.isNotEmpty) {
      _controller.text = savedUsername;
    }
  }

  Future<void> _submitUsername() async {
    if (_formKey.currentState!.validate()) {
      final username = _controller.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('github_username', username);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username saved successfully')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(username: username),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.blueGrey[50],
      body: Center(
        child: Card(
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GitHub logo
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Octicons-mark-github.svg/1024px-Octicons-mark-github.svg.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error, color: Colors.red, size: 80);
                    },
                  ),
                  SizedBox(height: 20),
                  // Username input field
                  CustomTextField(
                    label: 'GitHub Username',
                    hintText: 'e.g. octocat',
                    icon: Icons.person_outline,
                    controller: _controller,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username cannot be empty';
                      }
                      if (value.contains(' ')) {
                        return 'Username cannot contain spaces';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitUsername,
                      icon: FaIcon(FontAwesomeIcons.arrowRight),
                      label: Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('github_username', username);

      // Confirm to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username saved successfully')),
      );

      // Navigate to ProfileScreen
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
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter GitHub Username',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 20),
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
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitUsername,
                      child: Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

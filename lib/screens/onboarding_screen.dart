import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'username_input_screen.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🧭 GitHub Explorer title
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    "GitHub Explorer",  // Title text
                    style: TextStyle(
                      fontSize: 26,  // Font size for the title
                      fontWeight: FontWeight.bold,  // Bold font
                      color: Colors.black87,  // Dark color to match GitHub theme
                    ),
                  ),
                ),

                SizedBox(height: 30),  // Space after the title

                // 💬 GitHub tagline
                Text(
                  "Building the backbone of tomorrow’s software.",  // Tagline text
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,  // Slightly lighter than the title
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 30),  // Space after the tagline

                // 🌐 GitHub Lottie Animation
                Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_w51pcehl.json',  // Lottie animation URL
                  height: 250,  // Animation height
                  repeat: true,  // Animation repeats indefinitely
                  animate: true,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error, size: 80, color: Colors.red),  // Error handling
                ),

                SizedBox(height: 40),  // Space after the animation

                // 🚀 Get Started button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UsernameInputScreen()),
                    );
                  },
                  icon: Icon(Icons.arrow_forward),  // Arrow icon
                  label: Text('Get Started'),  // Button label
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),  // Rounded corners
                    ),
                    backgroundColor: Colors.black87,  // Button background color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

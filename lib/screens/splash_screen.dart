import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load environment variables
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Error loading .env file: ${e.toString()}');
      // Continue without .env file - we'll use mock data
    }

    // Simulate loading delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade600],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: 70,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // App name
            const Text(
              'AI Image Enhancer',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // App tagline
            const Text(
              'Transform your images with AI',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 50),
            // Loading spinner
            const SpinKitPulse(color: Colors.white, size: 50.0),
          ],
        ),
      ),
    );
  }
}

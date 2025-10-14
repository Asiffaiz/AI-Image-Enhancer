import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'core/theme/app_theme.dart';
import 'providers/credit_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('Error loading .env file: ${e.toString()}');
        // Continue without .env file - we'll use mock data
      }

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Set status bar color
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      // Run the app
      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');

      // Show toast for uncaught errors
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred',
        toastLength: Toast.LENGTH_SHORT,
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CreditBloc>(
          create: (context) => CreditBloc()..add(CheckCreditsEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'AI Image Enhancer',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        builder: (context, child) {
          // Error handling for widgets
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return Material(
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exception.toString(),
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const SplashScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Restart App'),
                    ),
                  ],
                ),
              ),
            );
          };

          return child!;
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:redhope/screens/login/signin_page.dart';
import 'package:redhope/screens/pages/home_page.dart';  // Import HomePage
import 'package:redhope/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style for light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
      statusBarBrightness: Brightness.light, // For iOS (dark icons)
    ),
  );

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
      // Configure Firestore
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    print('✅ Firebase and Firestore initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }
  
  runApp(const RedHope());
}

class RedHope extends StatelessWidget {
  const RedHope({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RedHope',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/home_page': (context) => const HomePage(),
        '/sign_in': (context) => SignInPage(),
      },
      builder: (context, child) {
        // Update status bar based on current theme brightness
        final brightness = MediaQuery.platformBrightnessOf(context);
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: brightness == Brightness.dark 
                ? Brightness.light 
                : Brightness.dark,
          )
        );
        
        // Apply a maximum width constraint to the entire app
        return MediaQuery(
          // Preserve original media query data but apply our constraints
          data: MediaQuery.of(context).copyWith(
            // Optional: adjust text scaling to ensure consistent text size
            textScaleFactor: 1.0,
          ),
          child: child!,
        );
      },
      home: SignInPage(),
    );
  }
}
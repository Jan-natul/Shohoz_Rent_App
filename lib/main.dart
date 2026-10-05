import 'package:app/screens/contact.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/screens/login.dart';
import 'package:app/screens/signup.dart';
import 'package:app/screens/about.dart';

import 'package:app/screens/profile.dart';
import 'package:app/screens/add_house.dart';
import 'package:app/screens/update.dart';
import 'package:app/screens/list.dart';
import 'package:app/screens/admin.dart';
import 'package:app/screens/post.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shohoz Rent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFF59E0B),
        scaffoldBackgroundColor: const Color(0xFF0A1018),
        useMaterial3: true,
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/about': (context) => const AboutScreen(),
        '/contact': (context) => const ContactScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/add': (context) => const AddHouseScreen(),
        '/update': (context) => const UpdateProfileScreen(),
        '/list': (context) => const ListScreen(),
        '/admin': (context) => const AdminDashboard(),
      },

      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/post/')) {
          final id = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => PostDetailScreen(id: id),
          );
        }
        return null;
      },
    );
  }
}
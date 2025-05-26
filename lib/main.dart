import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:roamie/firebase_options.dart';
import 'package:roamie/screens/Profile/user_friend_page.dart';
import 'screens/sign_in_page.dart';
import 'screens/sign_up_page.dart';
import 'screens/travel_plans_page.dart';
import 'screens/find_similar_people_page.dart';
import 'screens/Profile/profile_page.dart';
import 'components/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:roamie/provider/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create: (_) => UserProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roamie',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/signin',
      routes: {
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TravelPlansPage(),
    const FindSimilarPeoplePage(),
    const FriendsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SignInPage();
    }

    // Fetch profilePicture to pass to Nav Bar Profile Icon
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
      builder: (context, snapshot) {
        String? profilePictureBase64;
        String? profilePictureUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('profilePicture')) {
            final profilePicture = data['profilePicture'];
            if (profilePicture != null && profilePicture is String) {
              if (profilePicture.startsWith('http') ||
                  profilePicture.startsWith('https')) {
                profilePictureUrl = profilePicture;
              } else {
                profilePictureBase64 = profilePicture;
              }
            }
          }
        }

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            profilePictureBase64: profilePictureBase64,
            profilePictureUrl: profilePictureUrl,
          ),
        );
      },
    );
  }
}
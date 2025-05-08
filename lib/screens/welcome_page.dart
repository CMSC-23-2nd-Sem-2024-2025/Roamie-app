import 'package:flutter/material.dart';
import 'package:roamie/models/user_model.dart';

class WelcomePage extends StatelessWidget {
  final AppUser user;
  final VoidCallback onNext;

  const WelcomePage({super.key, required this.user, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Welcome,',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                '${user.username}!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'next',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    Icon(Icons.chevron_right),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'ROAMIE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepOrange,
                ),
              ),
              const Text(
                'Find your roaming buddy',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String?
  profilePictureBase64; // For Firebase account profile pic (base64)
  final String? profilePictureUrl; // For Google account profile pic (URL type)

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profilePictureBase64,
    this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget profileIcon;

    // Check if profilePictureUrl is provided and not empty
    if (profilePictureUrl?.isNotEmpty == true) {
      profileIcon = CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(profilePictureUrl!),
      );
    } else if (profilePictureBase64?.isNotEmpty == true) {
      final base64String = profilePictureBase64!;
      profileIcon = CircleAvatar(
        radius: 12,
        backgroundImage: MemoryImage(base64Decode(base64String)),
      );
    } else {
      profileIcon = CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey[200],
        child: Image.asset(
          'lib/assets/default_profilepic_roamie.png',
          width: 24,
          height: 24,
        ),
      );
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Travels'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Friends'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),

      ],
    );
  }
}

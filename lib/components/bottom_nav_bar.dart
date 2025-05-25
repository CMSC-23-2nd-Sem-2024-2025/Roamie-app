import 'package:flutter/material.dart';
import 'package:roamie/widgets/profile_picture_widget.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? profilePicture; // Single field for both URL and base64

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profilePicture,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home), 
          label: 'Travels'
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search), 
          label: 'Find'
        ),
        BottomNavigationBarItem(
          icon: ProfilePictureWidget(
            profilePicture: profilePicture,
            radius: 12,
            fallbackAsset: 'lib/assets/default_profilepic_roamie.png',
          ),
          label: 'Profile'
        ),
      ],
    );
  }
}
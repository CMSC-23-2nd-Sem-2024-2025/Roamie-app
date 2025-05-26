import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProfilePictureWidget extends StatelessWidget {
  final String? profilePicture;
  final double? radius;
  final String? fallbackAsset; // Optional custom fallback asset

  const ProfilePictureWidget({
    super.key,
    this.profilePicture,
    this.radius,
    this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return _buildProfilePicture(profilePicture);
  }

  Widget _buildProfilePicture(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return _buildFallbackAvatar();
    }

    // Check if it's a URL (starts with http/https)
    if (profilePicture.startsWith('http://') || profilePicture.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profilePicture),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle image loading error silently
        },
      );
    }
    
    // Otherwise, treat it as base64
    try {
      Uint8List imageBytes = base64Decode(profilePicture);
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(imageBytes),
      );
    } catch (e) {
      // If base64 decoding fails, show default avatar
      return _buildFallbackAvatar();
    }
  }
  
  Widget _buildFallbackAvatar() {
    if (fallbackAsset != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: Image.asset(
          fallbackAsset!,
          width: (radius ?? 20) * 1.2,
          height: (radius ?? 20) * 1.2,
        ),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        child: const Icon(Icons.person),
      );
    }
  }
}
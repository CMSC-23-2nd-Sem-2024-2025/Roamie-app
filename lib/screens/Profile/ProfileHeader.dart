import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:roamie/provider/user_provider.dart';

class ProfileHeader extends StatefulWidget {
  final String username;
  final String name;
  final String? userId;
  final List<String> interests;
  final List<String> travelStyles;
  final String? profilePictureBase64;  
  // to make user not edit the profile of friends
  final bool canEdit;


  const ProfileHeader({
    super.key,
    required this.username,
    required this.userId,
    required this.name,
    required this.interests,
    required this.travelStyles,
    this.profilePictureBase64,
    required this.canEdit
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  // Holds the image data as bytes for displaying the profile picture.
  // It will be initialized with the decoded base64 image from Firestore if available,
  // or with the newly picked image bytes.
  Uint8List? _image;

   @override
  void initState() {
    super.initState();
    // When the widget is first created, check if there's a profile picture stored as base64.
    // If so, decode it to Uint8List and assign it to _image to display it in the avatar.
    if (widget.profilePictureBase64 != null && widget.profilePictureBase64!.isNotEmpty) {
      try {
        _image = base64Decode(widget.profilePictureBase64!);
      } catch (e) {
        // optionally log error or ignore
      }
    }
  }

  // Pick Image for profile picture
 Future<void> _pickImage() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final userId = userProvider.userId;

  if (userId == null) return;

  // Show options to the user
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.of(context).pop(); // Close the bottom sheet
              final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
              await _handlePickedFile(file, userId, userProvider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () async {
              Navigator.of(context).pop(); // Close the bottom sheet
              final XFile? file = await ImagePicker().pickImage(source: ImageSource.camera);
              await _handlePickedFile(file, userId, userProvider);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _handlePickedFile(XFile? pickedFile, String userId, UserProvider userProvider) async {
  if (pickedFile == null) return;

  final Uint8List bytes = await pickedFile.readAsBytes();
  setState(() {
    _image = bytes;
  });

  final String base64Image = base64Encode(bytes);
  await userProvider.updateUser(userId, {'profilePicture': base64Image});
}

@override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              color: const Color(0xFF101653),
            ),
            const SizedBox(height: 100),
          ],
        ),
        Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
             onTap: widget.canEdit ? _pickImage : null,  // only allow tap if canEdit is true
              child: CircleAvatar(
                radius: 65,
                backgroundImage: _image != null ? MemoryImage(_image!) : null,
                backgroundColor: Colors.grey[300],
                child: _image == null
                    ? const Icon(Icons.add_a_photo, size: 30, color: Colors.white)
                    : null,
              ),
            ),
          ),
        Positioned(
          top: 40,
          left: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.username,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 25,
                  color: Color(0xFF101653),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


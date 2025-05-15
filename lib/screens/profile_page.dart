
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roamie/provider/user_provider.dart';
import 'package:image_picker/image_picker.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>{

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: userProvider.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No user data found.")),
          );
        }

        final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'Username';
        final name = "${userData['firstName']} ${userData['lastName']}";
        final interests = List<String>.from(userData['interests'] ?? []);
        final travelStyles = List<String>.from(userData['travelStyles'] ?? []);

        return Scaffold(
          body: SingleChildScrollView(
            // ensures the column fills at least the screen height.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // full screen
                minHeight: MediaQuery.of(context).size.height, 
              ),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Call all the widgets containing user info
                    ProfileHeader(
                      username: username,
                      name: name,
                      interests: interests,
                      travelStyles: travelStyles,
                    ),
                    const ContactsUser(),
                    const SizedBox(height: 20), 
                    // Label for Interests
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                      child: Text(
                        'Interests:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    interestGrid(interests),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                      child: Text(
                        'Travel Styles:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF101653),
                        ),
                      ),
                    ),
                    styleGrid(travelStyles),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
}

class ProfileHeader extends StatefulWidget {
  final String username;
  final String name;
  final List<String> interests;
  final List<String> travelStyles;

  const ProfileHeader({
    super.key,
    required this.username,
    required this.name,
    required this.interests,
    required this.travelStyles,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  Uint8List? _image;

  // Pick Image for profile picture
  Future<void> _pickImage() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final userId = userProvider.userId; 

  if (userId == null) {
    return;
  }

  final ImagePicker picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final Uint8List bytes = await pickedFile.readAsBytes();
    setState(() {
      _image = bytes;
    });

    String base64Image = base64Encode(bytes);

    // Update user document with profile picture
   await userProvider.updateUser(userId, {'profilePicture': base64Image});

  }
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
            onTap: _pickImage,
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
              const EditButton(),
            ],
          ),
        ),
      ],
    );
  }
}


class EditButton extends StatelessWidget {
  const EditButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () {
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF101653),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}


class ContactsUser extends StatelessWidget {
  const ContactsUser({super.key});

  @override
  Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Contact info',
                style: TextStyle(fontSize: 16),
              ),
              
            ],
          ),
        ),
      );
  }
}

// Grid builder for the Travel Styles and interest which are the two list string attributes of the user
Widget interestGrid(List<String> interests) {
  return Padding(
    
    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0), 
    child: GridView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      itemCount: interests.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Card(
          color: Colors.orange,
          child: Center(
            child: Text(
              interests[index],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    ),
  );
}

Widget styleGrid(List<String> travelStyles) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: travelStyles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Card(
          color: const Color(0xFF101653),
          child: Center(
            child: Text(
              travelStyles[index],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    ),
  );
}

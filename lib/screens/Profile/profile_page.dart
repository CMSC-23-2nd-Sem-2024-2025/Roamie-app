import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roamie/provider/user_provider.dart';
import 'package:roamie/screens/Profile/edit_button.dart';
import 'ProfileHeader.dart';
import 'list_grid.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            // Show loading screen
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No user data found.")),
          );
        }

        // get user info
        final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final username = userData['username'];
        final name = "${userData['firstName']} ${userData['lastName']}";
        final interests = List<String>.from(userData['interests'] ?? []); 
        final travelStyles = List<String>.from(userData['travelStyles'] ?? []);
        final profilePictureBase64 = userData['profilePicture'] ?? '';
        final isVisible = userData['isVisible'];

        // Access the userId
        final userId = userProvider.userId;

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
                      userId: userId,
                      username: username,
                      name: name,
                      interests: interests,
                      travelStyles: travelStyles,
                      profilePictureBase64: profilePictureBase64,
                      canEdit: true,
                    ),
                    // Edit and Sign Out buttons in a row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          EditControls(
                            username: username,
                            userId: userId!,
                            name: name,
                            interests: interests,
                            travelStyles: travelStyles,
                            isVisible: isVisible,
                          ),
                        ],
                      ),
                    ),

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
                    // Add sign out button at the bottom
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
                        }
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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



  





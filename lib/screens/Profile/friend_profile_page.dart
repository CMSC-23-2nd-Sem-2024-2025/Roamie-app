import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roamie/api/firebase_api_user.dart';
import 'ProfileHeader.dart';
import 'list_grid.dart';


// Friends Actual Profile
class FriendProfilePage extends StatelessWidget {
  final String friendUserId;

  const FriendProfilePage({super.key, required this.friendUserId});

  @override
  Widget build(BuildContext context) {
    // direct get friend info via api
    final userAPI = FirebaseUserAPI();
    return StreamBuilder<QuerySnapshot>(
      stream: userAPI.getUserInfo(friendUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("User not found.")),
          );
        }

        final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final username = userData['username'];
        final name = "${userData['firstName']} ${userData['lastName']}";
        final interests = List<String>.from(userData['interests'] ?? []);
        final travelStyles = List<String>.from(userData['travelStyles'] ?? []);
        final profilePictureBase64 = userData['profilePicture'] ?? '';
        final isVisible = userData['isVisible'];

        return Scaffold(
  appBar: AppBar(title: Text('$username\'s Profile')),
  body: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileHeader(
          username: username,
          userId: friendUserId,
          name: name,
          interests: interests,
          travelStyles: travelStyles,
          profilePictureBase64: profilePictureBase64,
          canEdit: false,
        ),

        if (isVisible) ...[
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Interests:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
          interestGrid(interests),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Travel Styles:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF101653)),
            ),
          ),
          styleGrid(travelStyles),
        ] else ...[
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'This user\'s profile is hidden.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    ),
  ),
);
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roamie/api/firebase_api_user.dart';
import 'package:roamie/provider/user_provider.dart';
import 'dart:convert';
import 'friend_profile_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FirebaseUserAPI api = FirebaseUserAPI();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final docId = userProvider.currentUserDocumentId;

    // Show loading screen while still geting docId
    if (docId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Friends',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF101653),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No friends yet'));
          }

          // Get friends info then display
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final friendDoc = snapshot.data!.docs[index];
              final friendData = friendDoc.data() as Map<String, dynamic>;
              final friendUserId = friendData['userId'];

              return FutureBuilder<QuerySnapshot>(
                future: api.getUserInfo(friendUserId).first,
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(child: CircularProgressIndicator()),
                      title: Text('Loading...'),
                    );
                  }

                  if (userSnapshot.hasError ||
                      !userSnapshot.hasData ||
                      userSnapshot.data!.docs.isEmpty) {
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.error)),
                      title: Text(friendData['username']),
                      subtitle: Text('User ID: $friendUserId'),
                    );
                  }

                  final userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final displayName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                  final username = userData['username'] ?? '';
                  final profilePic = userData['profilePicture'] ?? '';

                  return ListTile(
                    leading: profilePic.isEmpty
                        ? const CircleAvatar(child: Icon(Icons.person))
                        : _buildProfilePicture(profilePic),
                    title: Text(displayName.isNotEmpty ? displayName : username),
                    subtitle: username.isNotEmpty ? Text('@$username') : null,
                    trailing: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red.shade300, // Fill color
                                  foregroundColor: Colors.white, // Text color
                                  side: BorderSide(color: Colors.red.shade700), // Border color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4), // Less rounding for a more rectangular look
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Remove'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Removal'),
                            content: const Text(
                                'Are you sure you want to remove this friend?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                             TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red.shade300, // Fill color
                                  foregroundColor: Colors.white, // Text color
                                  side: BorderSide(color: Colors.red.shade700), // Border color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4), // Less rounding for a more rectangular look
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Remove'),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(docId)
                                .collection('friends')
                                .doc(friendDoc.id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Friend removed')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to remove friend: $e')),
                            );
                          }
                        }
                      },
                    ),
                    onTap: () {
                      // Navigate to FriendProfilePage when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendProfilePage(
                            friendUserId: friendUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Widget _buildProfilePicture(String profilePic) {
  try {
    // convert then show profile
    final decodedBytes = base64Decode(profilePic);
    return CircleAvatar(
      backgroundImage: MemoryImage(decodedBytes),
    );
  } catch (_) {
    // Fallback to network image if it's not base64
    return CircleAvatar(
      backgroundImage: NetworkImage(profilePic),
    );
  }
}

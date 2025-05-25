import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roamie/widgets/profile_picture_widget.dart';
import 'dart:typed_data';
import 'dart:convert';

class FindSimilarPeoplePage extends StatefulWidget {
  const FindSimilarPeoplePage({super.key});

  @override
  State<FindSimilarPeoplePage> createState() => _FindSimilarPeoplePageState();
}

class _FindSimilarPeoplePageState extends State<FindSimilarPeoplePage> {
  late Future<List<Map<String, dynamic>>> _similarUsersFuture;

  @override
  void initState() {
    super.initState();
    _similarUsersFuture = _findSimilarUsers();
  }

  Future<List<Map<String, dynamic>>> _findSimilarUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      // Query for current user's document using userId field
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      
      if (userQuery.docs.isEmpty) {
        print('Current user document not found');
        return [];
      }
      
      final userData = userQuery.docs.first.data();
      final List<String> myInterests = List<String>.from(userData['interests'] ?? []);
      final List<String> myTravelStyles = List<String>.from(userData['travelStyles'] ?? []);

      print('Current user interests: $myInterests');
      print('Current user travel styles: $myTravelStyles');
      
      // If current user has no interests or travel styles, return empty list
      if (myInterests.isEmpty && myTravelStyles.isEmpty) {
        print('Current user has no interests or travel styles');
        return [];
      }

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> similarUsers = [];

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        
        // Skip current user by comparing userId field
        if (data['userId'] == currentUser.uid) continue;
        
        // Skip users who have isVisible set to false
        if (data['isVisible'] == false) continue;
        
        final List<String> interests = List<String>.from(data['interests'] ?? []);
        final List<String> travelStyles = List<String>.from(data['travelStyles'] ?? []);

        // Calculate actual matches
        int interestMatches = 0;
        int styleMatches = 0;
        
        // Count interest matches
        for (String myInterest in myInterests) {
          if (interests.contains(myInterest)) {
            interestMatches++;
          }
        }
        
        // Count travel style matches
        for (String myStyle in myTravelStyles) {
          if (travelStyles.contains(myStyle)) {
            styleMatches++;
          }
        }
        
        int totalMatches = interestMatches + styleMatches;

        print('User ${data['firstName']} ${data['lastName']}:');
        print('  - Interests: $interests');
        print('  - Travel Styles: $travelStyles');
        print('  - Interest matches: $interestMatches');
        print('  - Style matches: $styleMatches');
        print('  - Total matches: $totalMatches');

        // Only add users with actual matches
        if (totalMatches > 0) {
          similarUsers.add({
            'user': data,
            'matches': totalMatches,
            'interestMatches': interestMatches,
            'styleMatches': styleMatches,
          });
        }
      }

      similarUsers.sort((a, b) => b['matches'].compareTo(a['matches']));
      print('Found ${similarUsers.length} similar users');
      return similarUsers;
    } catch (e) {
      print('Error finding similar users: $e');
      return [];
    }
  }

  Widget _buildProfilePicture(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return const CircleAvatar(
        child: Icon(Icons.person),
      );
    }

    // Check if it's a URL (starts with http/https)
    if (profilePicture.startsWith('http://') || profilePicture.startsWith('https://')) {
      return CircleAvatar(
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
        backgroundImage: MemoryImage(imageBytes),
      );
    } catch (e) {
      // If base64 decoding fails, show default avatar
      return const CircleAvatar(
        child: Icon(Icons.person),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Similar People')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _similarUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No similar people found.'));
          }
          
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index]['user'];
              final matches = users[index]['matches'];
              final interestMatches = users[index]['interestMatches'];
              final styleMatches = users[index]['styleMatches'];
              
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: ProfilePictureWidget(
                    profilePicture: user['profilePicture'],
                  ),
                  title: Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user['interests'] != null && user['interests'].isNotEmpty)
                        Text('Interests: ${user['interests'].join(', ')}'),
                      if (user['travelStyles'] != null && user['travelStyles'].isNotEmpty)
                        Text('Travel Styles: ${user['travelStyles'].join(', ')}'),
                    ],
                  ),
                  isThreeLine: false,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
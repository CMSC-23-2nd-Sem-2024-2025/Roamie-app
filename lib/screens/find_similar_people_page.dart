import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roamie/widgets/profile_picture_widget.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:roamie/api/firebase_api_user.dart';

enum FriendStatus { none, requestSent, requestReceived, friends }

class FindSimilarPeoplePage extends StatefulWidget {
  const FindSimilarPeoplePage({super.key});

  @override
  State<FindSimilarPeoplePage> createState() => _FindSimilarPeoplePageState();
}

class _FindSimilarPeoplePageState extends State<FindSimilarPeoplePage> {
  late Future<List<Map<String, dynamic>>> _similarUsersFuture;
  final Map<String, FriendStatus> _friendStatuses = {};
  final FirebaseUserAPI _firebaseAPI = FirebaseUserAPI();

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
      
      // Safe null handling for interests and travel styles
      final List<String> myInterests = userData['interests'] != null 
          ? List<String>.from(userData['interests']) 
          : <String>[];
      final List<String> myTravelStyles = userData['travelStyles'] != null 
          ? List<String>.from(userData['travelStyles']) 
          : <String>[];

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
        
        // Skip current user by comparing userId field with null check
        if (data['userId'] == null || data['userId'] == currentUser.uid) continue;
        
        // Skip users who have isVisible set to false
        if (data['isVisible'] == false) continue;
        
        // Safe null handling for other users' data
        final List<String> interests = data['interests'] != null 
            ? List<String>.from(data['interests']) 
            : <String>[];
        final List<String> travelStyles = data['travelStyles'] != null 
            ? List<String>.from(data['travelStyles']) 
            : <String>[];

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

        // Safe string concatenation with null checks
        final firstName = data['firstName']?.toString() ?? '';
        final lastName = data['lastName']?.toString() ?? '';
        
        print('User $firstName $lastName:');
        print('  - Interests: $interests');
        print('  - Travel Styles: $travelStyles');
        print('  - Interest matches: $interestMatches');
        print('  - Style matches: $styleMatches');
        print('  - Total matches: $totalMatches');

        // Only add users with actual matches and valid userId
        if (totalMatches > 0 && data['userId'] != null) {
          // Use FirebaseUserAPI to check friend status
          String statusString = await _firebaseAPI.checkFriendStatus(currentUser.uid, data['userId']);
          FriendStatus friendStatus;
          switch (statusString) {
            case 'friends':
              friendStatus = FriendStatus.friends;
              break;
            case 'requestSent':
              friendStatus = FriendStatus.requestSent;
              break;
            case 'requestReceived':
              friendStatus = FriendStatus.requestReceived;
              break;
            default:
              friendStatus = FriendStatus.none;
          }
          _friendStatuses[data['userId'].toString()] = friendStatus;
          
          similarUsers.add({
            'user': data,
            'matches': totalMatches,
            'interestMatches': interestMatches,
            'styleMatches': styleMatches,
            'friendStatus': friendStatus,
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

  Widget _buildFriendButton(String otherUserId, FriendStatus status) {
    switch (status) {
      case FriendStatus.none:
        return ElevatedButton.icon(
          onPressed: () => _sendFriendRequest(otherUserId),
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Add Friend'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );
      
      case FriendStatus.requestSent:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('Request Sent'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
        );
      
      case FriendStatus.requestReceived:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => _acceptFriendRequest(otherUserId),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _rejectFriendRequest(otherUserId),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      
      case FriendStatus.friends:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, size: 16),
          label: const Text('Friends'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        );
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

  Future<void> _sendFriendRequest(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      // Get current user's data for request
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      if (userQuery.docs.isEmpty) return;
      final userData = userQuery.docs.first.data();
      final result = await _firebaseAPI.sendFriendRequest(currentUser.uid, otherUserId, userData);
      setState(() {
        _friendStatuses[otherUserId] = FriendStatus.requestSent;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    } catch (e) {
      print('Error sending friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending friend request: $e')),
        );
      }
    }
  }

  Future<void> _acceptFriendRequest(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final result = await _firebaseAPI.acceptFriendRequest(currentUser.uid, otherUserId);
      setState(() {
        _friendStatuses[otherUserId] = FriendStatus.friends;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting friend request: $e')),
        );
      }
    }
  }

  Future<void> _rejectFriendRequest(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final result = await _firebaseAPI.removeFriendship(currentUser.uid, otherUserId);
      setState(() {
        _friendStatuses[otherUserId] = FriendStatus.none;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    } catch (e) {
      print('Error rejecting friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting friend request: $e')),
        );
      }
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
              final String userId = user['userId']?.toString() ?? '';
              final friendStatus = _friendStatuses[userId] ?? FriendStatus.none;
              
              // Safe string handling for display
              final firstName = user['firstName']?.toString() ?? '';
              final lastName = user['lastName']?.toString() ?? '';
              final fullName = '$firstName $lastName'.trim();
              
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfilePictureWidget(
                            profilePicture: user['profilePicture']?.toString(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName.isNotEmpty ? fullName : 'Anonymous User',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$matches match${matches > 1 ? 'es' : ''} ($interestMatches interests, $styleMatches styles)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (user['interests'] != null && user['interests'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Interests:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: (user['interests'] as List<dynamic>)
                                    .map((interest) => Chip(
                                          label: Text(interest?.toString() ?? ''),
                                          backgroundColor: Colors.blue[100],
                                          labelStyle: const TextStyle(fontSize: 12),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      if (user['travelStyles'] != null && user['travelStyles'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Travel Styles:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: (user['travelStyles'] as List<dynamic>)
                                    .map((style) => Chip(
                                          label: Text(style?.toString() ?? ''),
                                          backgroundColor: Colors.green[100],
                                          labelStyle: const TextStyle(fontSize: 12),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      if (userId.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildFriendButton(userId, friendStatus),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
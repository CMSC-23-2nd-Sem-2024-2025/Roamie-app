import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserAPI {

  // Create Instance
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // Function for adding users
  Future<String> addUser(Map<String, dynamic> userData) async {
    try {
      await db.collection("users").add(userData);
      return "Successfully added user!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}': ${e.message}";
    }
   }
   

  // Editing Function
  Future<String> updateUserByUserId(String userId, Map<String, dynamic> data) async {
  try {
    final querySnapshot = await db.collection('users')
      .where('userId', isEqualTo: userId)
      .get();

    if (querySnapshot.docs.isEmpty) {
      return 'No user found with userId: $userId';
    }

    final docId = querySnapshot.docs.first.id;

    await db.collection('users').doc(docId).update(data);

    return 'User updated successfully'; 
  } catch (e) {
    return 'Failed to update user: $e';
  }
}

  // Get the user info via user id
  Stream<QuerySnapshot> getUserInfo(String userId) {
    return db.collection('users').where('userId', isEqualTo: userId).snapshots(); 
  }

  
   // Fetch all users
  Stream<QuerySnapshot> getAllUsers() {
    return db.collection('users').snapshots();
  }

  // ===== FRIEND MANAGEMENT FUNCTIONS =====

  // Get user's friends
  Future<List<Map<String, dynamic>>> getUserFriends(String userId) async {
    try {
      final userQuery = await db.collection('users')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (userQuery.docs.isEmpty) {
        return [];
      }

      final userDocId = userQuery.docs.first.id;
      final friendsSnapshot = await db.collection('users')
          .doc(userDocId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      List<Map<String, dynamic>> friends = [];
      
      for (var friendDoc in friendsSnapshot.docs) {
        final friendUserId = friendDoc.data()['userId'];
        
        // Get friend's user info
        final friendUserQuery = await db.collection('users')
            .where('userId', isEqualTo: friendUserId)
            .get();
        
        if (friendUserQuery.docs.isNotEmpty) {
          final friendUserData = friendUserQuery.docs.first.data();
          friends.add({
            'userId': friendUserId,
            'userData': friendUserData,
            'friendshipData': friendDoc.data(),
          });
        }
      }

      return friends;
    } catch (e) {
      print('Error getting user friends: $e');
      return [];
    }
  }

  // Get pending friend requests (received) - FIXED VERSION
  Future<List<Map<String, dynamic>>> getPendingFriendRequests(String userId) async {
    try {
      print('Getting pending friend requests for userId: $userId');
      
      final userQuery = await db.collection('users')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (userQuery.docs.isEmpty) {
        print('User document not found for userId: $userId');
        return [];
      }

      final userDocId = userQuery.docs.first.id;
      print('Found user document ID: $userDocId');
      
      // Get all pending requests in this user's friends subcollection
      final requestsSnapshot = await db.collection('users')
          .doc(userDocId)
          .collection('friends')
          .where('status', isEqualTo: 'pending')
          .get();

      print('Found ${requestsSnapshot.docs.length} pending friend documents');

      List<Map<String, dynamic>> requests = [];
      
      for (var requestDoc in requestsSnapshot.docs) {
        final requestData = requestDoc.data();
        final requestedBy = requestData['requestedBy'];
        final friendUserId = requestData['userId'];
        
        print('Processing request: requestedBy=$requestedBy, friendUserId=$friendUserId, currentUserId=$userId');
        
        // Only include requests that were NOT sent by the current user
        // (i.e., requests received by the current user)
        if (requestedBy != userId) {
          // Get requester's user info
          final requesterQuery = await db.collection('users')
              .where('userId', isEqualTo: friendUserId)
              .get();
          
          if (requesterQuery.docs.isNotEmpty) {
            final requesterData = requesterQuery.docs.first.data();
            print('Adding request from user: ${requesterData['firstName']} ${requesterData['lastName']}');
            
            requests.add({
              'userId': friendUserId,
              'userData': requesterData,
              'requestData': requestData,
            });
          } else {
            print('Requester user data not found for userId: $friendUserId');
          }
        } else {
          print('Skipping request sent by current user');
        }
      }

      print('Returning ${requests.length} pending friend requests');
      return requests;
    } catch (e) {
      print('Error getting pending friend requests: $e');
      return [];
    }
  }

  // Send friend request
  Future<String> sendFriendRequest(String currentUserId, String targetUserId, Map<String, dynamic> currentUserData) async {
    try {
      print('Sending friend request from $currentUserId to $targetUserId');
      
      // Get both users' document IDs
      final currentUserQuery = await db.collection('users')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final targetUserQuery = await db.collection('users')
          .where('userId', isEqualTo: targetUserId)
          .get();

      if (currentUserQuery.docs.isEmpty || targetUserQuery.docs.isEmpty) {
        return 'User documents not found';
      }

      final currentUserDocId = currentUserQuery.docs.first.id;
      final targetUserDocId = targetUserQuery.docs.first.id;

      final batch = db.batch();

      // Add friend request to current user's friends subcollection
      final currentUserFriendRef = db.collection('users')
          .doc(currentUserDocId)
          .collection('friends')
          .doc(targetUserId);

      batch.set(currentUserFriendRef, {
        'userId': targetUserId,
        'status': 'pending',
        'requestedBy': currentUserId,
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // Add friend request to target user's friends subcollection
      final targetUserFriendRef = db.collection('users')
          .doc(targetUserDocId)
          .collection('friends')
          .doc(currentUserId);

      batch.set(targetUserFriendRef, {
        'userId': currentUserId,
        'status': 'pending',
        'requestedBy': currentUserId,
        'requestedAt': FieldValue.serverTimestamp(),
        'requesterName': '${currentUserData['firstName'] ?? ''} ${currentUserData['lastName'] ?? ''}',
      });

      await batch.commit();
      print('Friend request sent successfully');
      return 'Friend request sent successfully';
    } catch (e) {
      print('Error sending friend request: $e');
      return 'Error sending friend request: $e';
    }
  }

  // Accept friend request
  Future<String> acceptFriendRequest(String currentUserId, String requesterUserId) async {
    try {
      // Get both users' document IDs
      final currentUserQuery = await db.collection('users')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final requesterQuery = await db.collection('users')
          .where('userId', isEqualTo: requesterUserId)
          .get();

      if (currentUserQuery.docs.isEmpty || requesterQuery.docs.isEmpty) {
        return 'User documents not found';
      }

      final currentUserDocId = currentUserQuery.docs.first.id;
      final requesterDocId = requesterQuery.docs.first.id;

      final batch = db.batch();

      // Update current user's friend document
      final currentUserFriendRef = db.collection('users')
          .doc(currentUserDocId)
          .collection('friends')
          .doc(requesterUserId);

      batch.update(currentUserFriendRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update requester's friend document
      final requesterFriendRef = db.collection('users')
          .doc(requesterDocId)
          .collection('friends')
          .doc(currentUserId);

      batch.update(requesterFriendRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return 'Friend request accepted successfully';
    } catch (e) {
      return 'Error accepting friend request: $e';
    }
  }

  // Reject/Remove friend request or friendship
  Future<String> removeFriendship(String currentUserId, String otherUserId) async {
    try {
      // Get both users' document IDs
      final currentUserQuery = await db.collection('users')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final otherUserQuery = await db.collection('users')
          .where('userId', isEqualTo: otherUserId)
          .get();

      if (currentUserQuery.docs.isEmpty || otherUserQuery.docs.isEmpty) {
        return 'User documents not found';
      }

      final currentUserDocId = currentUserQuery.docs.first.id;
      final otherUserDocId = otherUserQuery.docs.first.id;

      final batch = db.batch();

      // Delete from current user's friends subcollection
      final currentUserFriendRef = db.collection('users')
          .doc(currentUserDocId)
          .collection('friends')
          .doc(otherUserId);

      batch.delete(currentUserFriendRef);

      // Delete from other user's friends subcollection
      final otherUserFriendRef = db.collection('users')
          .doc(otherUserDocId)
          .collection('friends')
          .doc(currentUserId);

      batch.delete(otherUserFriendRef);

      await batch.commit();
      return 'Friendship removed successfully';
    } catch (e) {
      return 'Error removing friendship: $e';
    }
  }

  // Check friend status between two users
  Future<String> checkFriendStatus(String currentUserId, String otherUserId) async {
    try {
      final userQuery = await db.collection('users')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (userQuery.docs.isEmpty) {
        return 'none';
      }

      final userDocId = userQuery.docs.first.id;
      final friendDoc = await db.collection('users')
          .doc(userDocId)
          .collection('friends')
          .doc(otherUserId)
          .get();

      if (friendDoc.exists) {
        final data = friendDoc.data()!;
        if (data['status'] == 'accepted') {
          return 'friends';
        } else if (data['status'] == 'pending') {
          if (data['requestedBy'] == currentUserId) {
            return 'requestSent';
          } else {
            return 'requestReceived';
          }
        }
      }

      return 'none';
    } catch (e) {
      print('Error checking friend status: $e');
      return 'none';
    }
  }

  // Get friends count
  Future<int> getFriendsCount(String userId) async {
    try {
      final userQuery = await db.collection('users')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (userQuery.docs.isEmpty) {
        return 0;
      }

      final userDocId = userQuery.docs.first.id;
      final friendsSnapshot = await db.collection('users')
          .doc(userDocId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      return friendsSnapshot.docs.length;
    } catch (e) {
      print('Error getting friends count: $e');
      return 0;
    }
  }

  // Stream of friend requests (for real-time updates)
  Stream<QuerySnapshot> getFriendRequestsStream(String userId) {
    return db.collection('users')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((userSnapshot) async {
      if (userSnapshot.docs.isEmpty) {
        return Future.value(null);
      }

      final userDocId = userSnapshot.docs.first.id;
      return db.collection('users')
          .doc(userDocId)
          .collection('friends')
          .where('status', isEqualTo: 'pending')
          .where('requestedBy', isNotEqualTo: userId)
          .snapshots()
          .first;
    }).where((snapshot) => snapshot != null).cast<QuerySnapshot>();
  }

  // Stream of friends (for real-time updates)
  Stream<QuerySnapshot> getFriendsStream(String userId) {
    return db.collection('users')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((userSnapshot) async {
      if (userSnapshot.docs.isEmpty) {
        return Future.value(null);
      }

      final userDocId = userSnapshot.docs.first.id;
      return db.collection('users')
          .doc(userDocId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .snapshots()
          .first;
    }).where((snapshot) => snapshot != null).cast<QuerySnapshot>();
  }

  // Search users by name or email (for friend search functionality)
  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserId) async {
    try {
      final usersSnapshot = await db.collection('users').get();
      List<Map<String, dynamic>> results = [];

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        
        // Skip current user
        if (data['userId'] == currentUserId) continue;
        
        // Skip users who have isVisible set to false
        if (data['isVisible'] == false) continue;
        
        final firstName = (data['firstName'] ?? '').toString().toLowerCase();
        final lastName = (data['lastName'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final queryLower = query.toLowerCase();
        
        // Check if query matches name or email
        if (firstName.contains(queryLower) || 
            lastName.contains(queryLower) || 
            email.contains(queryLower) ||
            '$firstName $lastName'.contains(queryLower)) {
          results.add(data);
        }
      }

      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
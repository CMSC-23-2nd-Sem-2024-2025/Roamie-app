import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roamie/provider/user_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
        final name = "${userData['firstName']} ${userData['lastName']}" ?? 'Name';
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

class ProfileHeader extends StatelessWidget {
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
        const Positioned(
          top: 20,
          left: 20,
          child: CircleAvatar(
            radius: 65,
          ),
        ),
        Positioned(
          top: 40,
          left: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                name,
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

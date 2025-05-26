import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roamie/provider/user_provider.dart';
import 'package:roamie/screens/Profile/edit_profile_page.dart';

class EditControls extends StatefulWidget {
  final String username;
  final String name;
  final String userId;
  final List<String> interests;
  final List<String> travelStyles;
  final bool isVisible;

  const EditControls({
    super.key,
    required this.username,
    required this.userId,
    required this.name,
    required this.interests,
    required this.travelStyles,
    required this.isVisible,
  });

  @override
  State<EditControls> createState() => _EditControlsState();
}

class _EditControlsState extends State<EditControls> {
  late bool _toggleValue;

  @override
  void initState() {
    super.initState();
    _toggleValue = widget.isVisible;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label + Switch
            Row(
              children: [
                const Text(
                  'Hide Profile',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _toggleValue,
                  onChanged: (bool newValue) async {
                    setState(() {
                      _toggleValue = newValue;
                    });

                    // 🔄 Update Firestore
                    await userProvider.updateUser(widget.userId, {
                      'isVisible': newValue,
                    });
                  },
                  activeColor: const Color(0xFF101653),
                ),
              ],
            ),
            const SizedBox(width: 20),

            // Edit Profile Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(
                      userId: widget.userId,
                      firstName: widget.name.split(' ').first,
                      lastName: widget.name.split(' ').last,
                      interests: widget.interests,
                      travelStyles: widget.travelStyles,
                    ),
                  ),
                );
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
          ],
        ),
      ),
    );
  }
}

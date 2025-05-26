import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roamie/provider/user_provider.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final List interests;
  final List travelStyles;

  const EditProfilePage({super.key, required this.userId, required this.firstName, required this.lastName, required this.interests, required this.travelStyles});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _interestsController;
  late TextEditingController _travelStylesController;

  final _formKey = GlobalKey<FormState>();

  @override
  @override
void initState() {
  super.initState();
  _firstNameController = TextEditingController(text: widget.firstName);
  _lastNameController = TextEditingController(text: widget.lastName);
  _interestsController = TextEditingController(text: widget.interests.join(', '));
  _travelStylesController = TextEditingController(text: widget.travelStyles.join(', '));
}
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _interestsController.dispose();
    _travelStylesController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;

    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'interests': _interestsController.text.split(',').map((e) => e.trim()).toList(),
        'travelStyles': _travelStylesController.text.split(',').map((e) => e.trim()).toList(),
      };

      try {
        await userProvider.updateUser(userId, updatedData);
        Navigator.pop(context); // Go back to profile page
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF101653),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _interestsController,
                decoration: const InputDecoration(labelText: 'Interests (comma separated)'),
              ),
              TextFormField(
                controller: _travelStylesController,
                decoration: const InputDecoration(labelText: 'Travel Styles (comma separated)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, 
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

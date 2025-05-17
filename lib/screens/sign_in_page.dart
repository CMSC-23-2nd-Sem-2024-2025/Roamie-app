import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:roamie/screens/sign_up_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>(); // Add a GlobalKey for the form
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Dispose controllers
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    // Validate the form before attempting to sign in
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Query Firestore to get email using username
        final usersSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('username', isEqualTo: _usernameController.text.trim())
                .limit(1) // Assume usernames are unique
                .get();

        // Check if username exists
        if (usersSnapshot.docs.isEmpty) {
          setState(() {
            _errorMessage = 'No user found with that username.';
            _isLoading = false;
          });
          return;
        }

        final userData = usersSnapshot.docs.first.data();
        final email = userData['email'];

        // Sign in with email and password using Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: email,
              password: _passwordController.text,
            );

        // Handle successful sign-in and fetch user data from Firestore
        if (userCredential.user != null) {
          // Navigate to home page
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            '/home',
          ); // Navigate to home page
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getFirebaseErrorMessage(e.code);
        });
      } catch (e) {
        setState(() {
          _errorMessage = "An unexpected error occurred. Please try again.";
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // If the user canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // Successful sign-in and fetch user data from Firestore
      if (userCredential.user != null) {
        final String userId = userCredential.user!.uid;
        final User? firebaseUser = userCredential.user;

        // Check if user data exists in Firestore
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

        if (!userDoc.exists) {
          // Create a new user document if it doesn't exist
          final newUser = {
            'userId': userId,
            'email': firebaseUser?.email,
            'firstName': '',
            'lastName': '',
            'username':
                firebaseUser?.email?.split(
                  '@',
                )[0], // Extract username from email
            'profilePicture':
                firebaseUser?.photoURL, // Google profile picture URL
            'isVisible': true,
            'travelStyles': [],
            'interests': [],
          };

          // Extract first and last names from displayName
          final displayNameParts = firebaseUser?.displayName?.split(' ');
          if (displayNameParts != null && displayNameParts.isNotEmpty) {
            newUser['firstName'] = displayNameParts[0];
            if (displayNameParts.length > 1) {
              newUser['lastName'] = displayNameParts.sublist(1).join(' ');
            }
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(newUser);
        }

        // Navigate to home page
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/home',
        ); // Navigate to home page
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Google sign in failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      default:
        return 'An error occurred during sign in. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Added SingleChildScrollView for handling overflow
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // ROAMIE title
                const Text(
                  'ROAMIE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find your roaming buddy',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                // Login title
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Login',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                ),
                const SizedBox(height: 24),
                // Show error message if there is one
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'USERNAME',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black54,
                            letterSpacing: 1.2,
                          ),
                          hintText: 'Enter your username',
                          border: OutlineInputBorder(
                            // Rounded border
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF2F2F2),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'PASSWORD',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black54,
                            letterSpacing: 1.2,
                          ),
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF2F2F2),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed:
                              _isLoading
                                  ? null
                                  : _signInWithEmailAndPassword, // Disable when loading
                          child:
                              _isLoading // Loading indicator is shown if app tries to sign in/validate auth
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Log in',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'lib/assets/sign-in/google_logo.png', // Google logo Branding
                                height: 24.0,
                                width: 24.0,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // If user has no account yet
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No account yet?',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _navigateToSignUp, // Navigate to sign up page
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

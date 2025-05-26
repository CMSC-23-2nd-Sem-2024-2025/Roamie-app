import 'dart:convert';

class AppUser {
  String? id;
  String firstName;
  String lastName;
  String email;
  String username;
  List<String>? travelStyles;
  List<String>? interests;
  // base64
  String? profilePicture; 
  bool isVisible;
  // foreign key for accessing the user's info
  String userId;

  AppUser({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    //  Interest, Style and Profile are nullable
    this.travelStyles,
    this.interests,
    this.profilePicture,
    required this.isVisible,
    required this.userId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      username: json['username'],
      travelStyles: List<String>.from(json['travelStyles'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      profilePicture: json['profilePicture'],
      isVisible: json['isVisible'],
      userId: json['userId'],
    );
  }

  static List<AppUser> fromJsonArray(String jsonData) {
    final Iterable<dynamic> data = jsonDecode(jsonData);
    return data.map<AppUser>((dynamic d) => AppUser.fromJson(d)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'travelStyles': travelStyles,
      'interests': interests,
      'profilePicture': profilePicture,
      'isVisible': isVisible,
      'userId': userId,
    };
  }
}

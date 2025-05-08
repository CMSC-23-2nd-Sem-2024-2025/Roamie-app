import 'dart:convert';

class AppUser {
  String? id;
  String fname;
  String lname;
  String email;
  String userName;
  String travelStyle;
  List<String>? interests;
  // base64
  String? profilePicture; 
  bool isVisible;
  // foreign key for accessing the user's info
  String userId;

  AppUser({
    this.id,
    required this.fname,
    required this.lname,
    required this.email,
    required this.userName,
    required this.travelStyle,
    // Interest and Profile are nullable
    this.interests,
    this.profilePicture,
    this.isVisible = true,
    required this.userId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      fname: json['fname'],
      lname: json['lname'],
      email: json['email'],
      userName: json['userName'],
      travelStyle: json['travelStyle'],
      // if interest is empty set it to null
      interests: List<String>.from(json['interests'] ?? []),
      profilePicture: json['profilePicture'],
      isVisible: json['isVisible'] ?? true,
      userId: json['userId'],
    );
  }

  static List<AppUser> fromJsonArray(String jsonData) {
    final Iterable<dynamic> data = jsonDecode(jsonData);
    return data.map<AppUser>((dynamic d) => AppUser.fromJson(d)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'fname': fname,
      'lname': lname,
      'email': email,
      'userName': userName,
      'travelStyle': travelStyle,
      'interests': interests,
      'profilePicture': profilePicture,
      'isVisible': isVisible,
      'userId': userId,
    };
  }
}

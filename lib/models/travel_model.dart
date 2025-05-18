class TravelPlan {
  String? id;
  String place;
  String location;
  String startDate; // Format: YYYY-MM-DD
  String endDate; // Format: YYYY-MM-DD
  String notes;
  // Optional image stored as URL (uploaded via Firebase Storage)
  String? imageUrl;
  // ownerId = UID of the user who created the plan
  String ownerId;
  // sharedWith = list of usernames or UIDs the plan is shared with
  List<String>? sharedWith;

  TravelPlan({
    this.id,
    required this.place,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.notes,
    this.imageUrl,
    required this.ownerId,
    this.sharedWith,
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    return TravelPlan(
      id: json['id'],
      place: json['place'],
      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      ownerId: json['ownerId'],
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place': place,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'sharedWith': sharedWith ?? [],
    };
  }
}

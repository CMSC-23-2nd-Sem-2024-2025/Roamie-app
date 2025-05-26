class TravelPlan {
  String? id;
  String place;
  String location;
  String startDate; // Format: YYYY-MM-DD
  String endDate; // Format: YYYY-MM-DD
  String notes;
  String? imageUrl; // Optional: from Firebase Storage
  String? imageBase64; // Optional: base64 image data
  String ownerId;
  List<String>? sharedWith;
  int? notificationDays;

  // Each itinerary entry can include day and detailed activities
  List<Map<String, String>> itinerary;

  TravelPlan({
    this.id,
    required this.place,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.notes,
    this.imageUrl,
    this.imageBase64,
    required this.ownerId,
    this.sharedWith,
    this.itinerary = const [],
    this.notificationDays,
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
      imageBase64: json['imageBase64'],
      ownerId: json['ownerId'],
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
      itinerary: (json['itinerary'] as List?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          [],
      notificationDays: json['notificationDays'],

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
      'imageBase64': imageBase64,
      'ownerId': ownerId,
      'sharedWith': sharedWith ?? [],
      'itinerary': itinerary,
      'notificationDays': notificationDays,
    };
  }
}

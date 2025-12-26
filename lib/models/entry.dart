class Entry {
  int? id; // Local DB ID
  String userId; // ✅ Current logged in user
  String title;
  String description;
  String category;
  String date; // ISO 8601 string
  String? mood; // ✅ New field
  String? imagePath;
  bool isSynced;

  Entry({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    this.mood = "😊", // ✅ Default mood
    this.imagePath,
    this.isSynced = false,
  });

  // Convert Entry to map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'date': date,
      'mood': mood, // ✅ Save mood
      'imagePath': imagePath,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Create Entry object from SQLite map
  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      userId: map['userId'] ?? "",
      title: map['title'] ?? "",
      description: map['description'] ?? "",
      category: map['category'] ?? "Routine",
      date: map['date'] ?? DateTime.now().toIso8601String(),
      mood: map['mood'] ?? "😊", // ✅ Load mood
      imagePath: map['imagePath'],
      isSynced: map['isSynced'] == 1,
    );
  }

  // Create a copy with updated fields
  Entry copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? date,
    String? mood,
    String? imagePath,
    bool? isSynced,
  }) {
    return Entry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      imagePath: imagePath ?? this.imagePath,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

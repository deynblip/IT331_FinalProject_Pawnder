// ===============================
// TEMPORARY IN-MEMORY REPORT STORE
// ===============================
// Reports submitted from the Report a Stray flow are stored here.
// This resets every time the app restarts.
// Replace submit() with Firebase / your own backend later.

enum Urgency { urgent, needsHelp, sighted }

class StrayReport {
  final String id;
  final String animalType;
  final Urgency urgency;
  final String description;
  final String? photoPath;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;

  StrayReport({
    required this.id,
    required this.animalType,
    required this.urgency,
    required this.description,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
  });
}

class ReportService {
  static final List<StrayReport> _reports = [];

  static List<StrayReport> get all => List.unmodifiable(_reports);

  static Future<void> submit({
    required String animalType,
    required Urgency urgency,
    required String description,
    required String? photoPath,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 700));

    _reports.insert(
      0,
      StrayReport(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        animalType: animalType,
        urgency: urgency,
        description: description,
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
        address: address,
        createdAt: DateTime.now(),
      ),
    );
  }
}
enum Urgency {
  urgent('urgent'),
  needsHelp('needs_help'),
  sighted('sighted');

  const Urgency(this.dbValue);
  final String dbValue;

  static Urgency fromDb(String? value) => Urgency.values.firstWhere(
        (u) => u.dbValue == value,
    orElse: () => Urgency.sighted,
  );
}

/// Rescue status. [dbValue] is how it is saved in the database.
enum RescueStatus {
  needsRescue('needs_rescue'),
  inProgress('in_progress'),
  rescued('rescued');

  const RescueStatus(this.dbValue);
  final String dbValue;

  static RescueStatus fromDb(String? value) => RescueStatus.values.firstWhere(
        (s) => s.dbValue == value,
    orElse: () => RescueStatus.needsRescue,
  );
}

extension UrgencyLabel on Urgency {
  String get label {
    switch (this) {
      case Urgency.urgent:
        return 'Urgent';
      case Urgency.needsHelp:
        return 'Needs Help';
      case Urgency.sighted:
        return 'Sighted';
    }
  }
}

extension RescueStatusLabel on RescueStatus {
  String get label {
    switch (this) {
      case RescueStatus.needsRescue:
        return 'Needs Rescue';
      case RescueStatus.inProgress:
        return 'Rescue in Progress';
      case RescueStatus.rescued:
        return 'Rescued';
    }
  }
}

class StrayReport {
  final String id;
  final String title;
  final String animalType; // Dog, Cat, Other
  final Urgency urgency;
  final RescueStatus status;
  final String location; // readable address
  final String description;

  /// The photo: a web link (reports from the database) or an asset path
  /// (sample data). Null = no photo. ReportImage handles both.
  final String? imageAsset;

  /// All photos of the report (links from the database), first = cover.
  /// Use [allPhotos] when showing them.
  final List<String> photos;

  /// Distance from the user's phone. Null = location unknown.
  final double? distanceKm;

  final DateTime date;
  final double lat;
  final double lng;

  /// Number of people currently responding ("I'm on my way!").
  final int responders;

  /// True when the logged-in user made this report.
  final bool isMine;

  /// Reporter ticked "Has a collar / looks like someone's pet".
  final bool possiblyLostPet;

  /// Database only: who made the report, and how the rescue ended.
  final String? reporterId;
  final String? outcome; // e.g. 'rescued_on_site' (database value)
  final String? closedBy; // user id of the person who marked it rescued

  const StrayReport({
    required this.id,
    required this.title,
    required this.animalType,
    required this.urgency,
    required this.status,
    required this.location,
    required this.date,
    required this.lat,
    required this.lng,
    this.description = '',
    this.imageAsset,
    this.photos = const [],
    this.distanceKm,
    this.responders = 0,
    this.isMine = false,
    this.possiblyLostPet = false,
    this.reporterId,
    this.outcome,
    this.closedBy,
  });

  /// Builds a report from a `stray_reports` row.
  factory StrayReport.fromRow(
      Map<String, dynamic> row, {
        required String? currentUserId,
        List<String> photoUrls = const [],
        int responders = 0,
        double? distanceKm,
      }) {
    final String animal = (row['animal_type'] as String?) ?? 'Other';
    final bool lostPet = row['possibly_lost_pet'] == true;
    final String? reporterId = row['reporter_id'] as String?;

    return StrayReport(
      id: row['id'] as String,
      title: titleFor(animal, lostPet),
      animalType: animal,
      urgency: Urgency.fromDb(row['urgency'] as String?),
      status: RescueStatus.fromDb(row['rescue_status'] as String?),
      location: (row['address'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      imageAsset: photoUrls.isEmpty ? null : photoUrls.first,
      photos: photoUrls,
      distanceKm: distanceKm,
      date: DateTime.parse(row['created_at'] as String).toLocal(),
      lat: (row['latitude'] as num).toDouble(),
      lng: (row['longitude'] as num).toDouble(),
      responders: responders,
      isMine: reporterId != null && reporterId == currentUserId,
      possiblyLostPet: lostPet,
      reporterId: reporterId,
      outcome: row['outcome'] as String?,
      closedBy: row['closed_by'] as String?,
    );
  }

  /// Title shown on cards, e.g. "Stray Dog" or "Possibly Lost Cat".
  static String titleFor(String animalType, bool possiblyLostPet) {
    final String animal = animalType == 'Other' ? 'Animal' : animalType;
    return possiblyLostPet ? 'Possibly Lost $animal' : 'Stray $animal';
  }

  /// "350 m", "1.2 km", "3 km", or "Distance unknown".
  String get distanceText {
    final double? km = distanceKm;
    if (km == null) return 'Distance unknown';
    if (km < 1) return '${(km * 1000).round()} m';
    final String text = km.toStringAsFixed(1);
    return text.endsWith('.0')
        ? '${text.substring(0, text.length - 2)} km'
        : '$text km';
  }

  String get dateText {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Every photo to show (falls back to the single cover photo).
  List<String> get allPhotos => photos.isNotEmpty
      ? photos
      : ((imageAsset ?? '').isNotEmpty ? [imageAsset!] : const []);

  String get descriptionOrDefault =>
      description.trim().isEmpty ? 'No details provided.' : description;

  StrayReport copyWith({
    RescueStatus? status,
    int? responders,
    double? distanceKm,
  }) {
    return StrayReport(
      id: id,
      title: title,
      animalType: animalType,
      urgency: urgency,
      status: status ?? this.status,
      location: location,
      description: description,
      imageAsset: imageAsset,
      photos: photos,
      distanceKm: distanceKm ?? this.distanceKm,
      date: date,
      lat: lat,
      lng: lng,
      responders: responders ?? this.responders,
      isMine: isMine,
      possiblyLostPet: possiblyLostPet,
      reporterId: reporterId,
      outcome: outcome,
      closedBy: closedBy,
    );
  }
}
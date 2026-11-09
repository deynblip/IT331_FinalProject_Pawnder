enum Urgency { urgent, needsHelp, sighted }

enum RescueStatus { needsRescue, inProgress, rescued }

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
  final String location;
  final String description;
  final String? imageAsset; // later: imageUrl galing sa backend
  final double distanceKm;
  final DateTime date;
  final double lat;
  final double lng;
  final int responders;

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
    this.distanceKm = 0,
    this.responders = 0,
  });

  String get distanceText => distanceKm == distanceKm.roundToDouble()
      ? '${distanceKm.toInt()} km'
      : '$distanceKm km';

  String get dateText {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get descriptionOrDefault =>
      description.trim().isEmpty ? 'No description provided.' : description;

  StrayReport copyWith({RescueStatus? status, int? responders}) {
    return StrayReport(
      id: id,
      title: title,
      animalType: animalType,
      urgency: urgency,
      status: status ?? this.status,
      location: location,
      description: description,
      imageAsset: imageAsset,
      distanceKm: distanceKm,
      date: date,
      lat: lat,
      lng: lng,
      responders: responders ?? this.responders,
    );
  }
}
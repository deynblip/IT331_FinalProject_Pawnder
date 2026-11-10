enum ApplicationStatus { pendingScreening, approved, rejected }

extension ApplicationStatusX on ApplicationStatus {
  String get label => switch (this) {
    ApplicationStatus.pendingScreening => 'Pending Screening',
    ApplicationStatus.approved => 'Approved',
    ApplicationStatus.rejected => 'Rejected',
  };
}

class AdoptionApplication {
  final String id;

  // Link to the selected pet and its original poster
  final String petId;
  final String petName;
  final String posterName;

  // Applicant information
  final String fullName;
  final String phone;
  final String email;

  // Address
  final String province;
  final String city;
  final String barangay;
  final String street;

  // Experience / environment
  final String homeEnvironment;
  final String householdMembers;
  final String previousPets;
  final String careExperience;

  final ApplicationStatus status;
  final DateTime createdAt;

  const AdoptionApplication({
    required this.id,
    required this.petId,
    required this.petName,
    required this.posterName,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.province,
    required this.city,
    required this.barangay,
    required this.street,
    required this.homeEnvironment,
    required this.householdMembers,
    required this.previousPets,
    required this.careExperience,
    required this.status,
    required this.createdAt,
  });

  /// Example: "Alangilan, Batangas City, Batangas"
  String get location => '$barangay, $city, $province';
}
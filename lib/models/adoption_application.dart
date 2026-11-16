enum ApplicationStatus {
  pendingScreening,
  forwardedToOwner,
  approved,
  rejected,
}

extension ApplicationStatusX on ApplicationStatus {
  String get label => switch (this) {
    ApplicationStatus.pendingScreening => 'Pending Review',
    ApplicationStatus.forwardedToOwner => 'Forwarded to Pet Owner',
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

  // Who submitted it, and why it was rejected (if it was).
  final String applicantEmail;
  final String? rejectionReason;

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
    required this.applicantEmail,
    this.rejectionReason,
  });

  /// Example: "November 12, 2026"
  String get dateText {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  /// Example: "Alangilan, Batangas City, Batangas"
  String get location => '$barangay, $city, $province';

  AdoptionApplication copyWith({
    ApplicationStatus? status,
    String? rejectionReason,
  }) {
    return AdoptionApplication(
      id: id,
      petId: petId,
      petName: petName,
      posterName: posterName,
      fullName: fullName,
      phone: phone,
      email: email,
      province: province,
      city: city,
      barangay: barangay,
      street: street,
      homeEnvironment: homeEnvironment,
      householdMembers: householdMembers,
      previousPets: previousPets,
      careExperience: careExperience,
      status: status ?? this.status,
      createdAt: createdAt,
      applicantEmail: applicantEmail,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
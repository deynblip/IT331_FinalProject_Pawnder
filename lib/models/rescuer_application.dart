enum RescuerStatus {
  none, // never applied
  pending, // waiting for the admin
  verified, // approved
  rejected; // not approved (user can apply again)

  String get label => switch (this) {
    RescuerStatus.none => 'Not applied',
    RescuerStatus.pending => 'Pending Verification',
    RescuerStatus.verified => 'Verified',
    RescuerStatus.rejected => 'Rejected',
  };
}

class RescuerApplication {
  final String id;
  final String email;
  final String applicantName;
  final String organization;
  final String roleInOrg;
  final String contactPerson;
  final String contactNumber;
  final String officialPage; // Facebook page or website
  final DateTime submittedAt;
  final RescuerStatus status;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  const RescuerApplication({
    required this.id,
    required this.email,
    required this.applicantName,
    required this.organization,
    required this.roleInOrg,
    required this.contactPerson,
    required this.contactNumber,
    required this.officialPage,
    required this.submittedAt,
    this.status = RescuerStatus.pending,
    this.rejectionReason,
    this.reviewedAt,
  });

  RescuerApplication copyWith({
    RescuerStatus? status,
    String? rejectionReason,
    DateTime? reviewedAt,
  }) {
    return RescuerApplication(
      id: id,
      email: email,
      applicantName: applicantName,
      organization: organization,
      roleInOrg: roleInOrg,
      contactPerson: contactPerson,
      contactNumber: contactNumber,
      officialPage: officialPage,
      submittedAt: submittedAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
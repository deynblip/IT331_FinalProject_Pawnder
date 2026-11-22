/// Admin review state of a pet post.
///   pending  = just posted by a user, waiting for the admin
///   approved = admin allowed it -> visible on the Adopt board
///   rejected = admin did not allow it -> hidden from the Adopt board
enum PostStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
    PostStatus.pending => 'Pending',
    PostStatus.approved => 'Approved',
    PostStatus.rejected => 'Rejected',
  };
}

/// Where the pet comes from. Rescued strays are the priority on Pawnder.
enum PetSource {
  rescuedStray,
  rehoming;

  String get label => switch (this) {
    PetSource.rescuedStray => 'Rescued Stray',
    PetSource.rehoming => 'Rehoming',
  };

  /// Label of the reason field in the form and the details page.
  String get reasonLabel => switch (this) {
    PetSource.rescuedStray => 'Reason for Adoption',
    PetSource.rehoming => 'Reason for Rehoming',
  };
}

class AdoptionPet {
  final String id;
  final String name;
  final String animalType; // Dog, Cat, Other
  final String age; // free text, e.g. "1 year"
  final String sex; // Male / Female
  final String location; // e.g. "Alangilan, Batangas City"
  final String description;
  final String healthInfo;
  final String posterName;
  final List<String> photos;
  final bool isMine; // TEMP: pet posted by the logged-in user
  final String reasonForAdoption;
  final String contactPerson; // stored, but hidden until admin screening
  final String contactPhone;
  final String contactEmail;

  /// Admin review state. New posts start as pending.
  final PostStatus status;

  /// When the user posted it (shown on the admin Posts page).
  final DateTime? postedAt;

  /// Set when a Verified Rescuer posts it -> "Rescued by [Organization]".
  final String? rescuedBy;

  /// Why the admin rejected the post (only set while status = rejected).
  final String? rejectionReason;

  /// true = the owner edited a reviewed post, so the admin must re-check it.
  final bool resubmitted;

  /// Account email of the poster (used to send the review notification).
  final String? ownerEmail;

  /// Rescued Stray (shown first on the board) or Owned Pet (Rehoming).
  final PetSource source;

  const AdoptionPet({
    required this.id,
    required this.name,
    required this.animalType,
    required this.age,
    required this.sex,
    required this.location,
    required this.posterName,
    this.description = '',
    this.healthInfo = '',
    this.photos = const [],
    this.isMine = false,
    this.reasonForAdoption = '',
    this.contactPerson = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.status = PostStatus.pending,
    this.postedAt,
    this.rescuedBy,
    this.rejectionReason,
    this.resubmitted = false,
    this.ownerEmail,
    this.source = PetSource.rescuedStray,
  });

  /// Example: "1 year · Male"
  String get summary => '$age · $sex';

  String? get coverPhoto => photos.isEmpty ? null : photos.first;

  String get descriptionOrDefault =>
      description.trim().isEmpty ? 'No description provided.' : description;

  String get healthInfoOrDefault => healthInfo.trim().isEmpty
      ? 'No health information provided.'
      : healthInfo;

  /// Used when the owner edits a post (or the admin changes its status).
  /// id, posterName, isMine, postedAt, rescuedBy and ownerEmail never change.
  ///
  /// The rejection reason is kept only while the post is rejected: when the
  /// status changes to pending or approved it is cleared automatically.
  AdoptionPet copyWith({
    String? name,
    String? animalType,
    String? age,
    String? sex,
    String? location,
    String? description,
    String? healthInfo,
    String? reasonForAdoption,
    List<String>? photos,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    PostStatus? status,
    String? rejectionReason,
    bool? resubmitted,
    PetSource? source,
  }) {
    final newStatus = status ?? this.status;

    return AdoptionPet(
      id: id,
      name: name ?? this.name,
      animalType: animalType ?? this.animalType,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      location: location ?? this.location,
      posterName: posterName,
      description: description ?? this.description,
      healthInfo: healthInfo ?? this.healthInfo,
      photos: photos ?? this.photos,
      isMine: isMine,
      reasonForAdoption: reasonForAdoption ?? this.reasonForAdoption,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      status: newStatus,
      postedAt: postedAt,
      rescuedBy: rescuedBy,
      rejectionReason: newStatus == PostStatus.rejected
          ? (rejectionReason ?? this.rejectionReason)
          : null,
      // A finished review (approve / reject) clears the "edited" flag.
      resubmitted: resubmitted ??
          ((status != null && status != PostStatus.pending)
              ? false
              : this.resubmitted),
      ownerEmail: ownerEmail,
      source: source ?? this.source,
    );
  }
}
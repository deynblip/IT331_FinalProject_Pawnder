// =====================================
// TEMPORARY IN-MEMORY APPLICATION STORE
// =====================================

import '../models/adoption_application.dart';
import '../models/adoption_pet.dart';

class ApplicationService {
  static final List<AdoptionApplication> _applications = [];

  static List<AdoptionApplication> get all =>
      List.unmodifiable(_applications);

  /// True if the user already applied for this pet.
  static bool hasApplied(String petId) =>
      _applications.any((a) => a.petId == petId);

  static Future<void> submit({
    required AdoptionPet pet,
    required String fullName,
    required String phone,
    required String email,
    required String province,
    required String city,
    required String barangay,
    required String street,
    required String homeEnvironment,
    required String householdMembers,
    required String previousPets,
    required String careExperience,
  }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 700));

    // Safety net: one application per pet.
    if (hasApplied(pet.id)) {
      throw StateError('Already applied for this pet.');
    }

    _applications.insert(
      0,
      AdoptionApplication(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        petId: pet.id,
        petName: pet.name,
        posterName: pet.posterName,
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
        status: ApplicationStatus.pendingScreening, // waits for admin screening
        createdAt: DateTime.now(),
      ),
    );
  }
}
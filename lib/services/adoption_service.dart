// ===================================
// TEMPORARY IN-MEMORY ADOPTION STORE
// ===================================

// Pets galing post nastore here
// sample pets. ma-resets every time the app restarts.
// Replace publish() and all with your real backend later.

import '../data/mock_adoption_pets.dart';
import '../models/adoption_pet.dart';

class AdoptionService {
  static final List<AdoptionPet> _pets = List.of(mockAdoptionPets);

  static List<AdoptionPet> get all => List.unmodifiable(_pets);
  static AdoptionPet? byId(String id) {
    for (final p in _pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Publishes a pet directly. There is NO admin approval step.
  static Future<void> publish({
    required String name,
    required String animalType,
    required String age,
    required String sex,
    required String location,
    required String description,
    required String healthInfo,
    required String reasonForAdoption,
    required String posterName,
    required List<String> photos,
    required String contactPerson,
    required String contactPhone,
    required String contactEmail,
  }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 700));

    _pets.insert(
      0,
      AdoptionPet(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        animalType: animalType,
        age: age,
        sex: sex,
        location: location,
        posterName: posterName,
        description: description,
        healthInfo: healthInfo,
        reasonForAdoption: reasonForAdoption,
        photos: photos,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        isMine: true, // posted by the logged-in user
      ),
    );
  }
}
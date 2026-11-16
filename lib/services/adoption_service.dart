// ===================================
// TEMPORARY IN-MEMORY ADOPTION STORE
// ===================================

// Pets galing post nastore here
// sample pets. ma-resets every time the app restarts.
// Replace publish() and all with your real backend later.

import 'package:flutter/foundation.dart';

import '../data/mock_adoption_pets.dart';
import '../models/adoption_pet.dart';

class AdoptionService {
  static final List<AdoptionPet> _pets = List.of(mockAdoptionPets);

  /// Bumps every time a pet is added, edited or removed so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notify() => changes.value++;

  static List<AdoptionPet> get all => List.unmodifiable(_pets);

  /// Pets posted by the logged-in user (Profile > My Adoption Posts).
  static List<AdoptionPet> get mine =>
      _pets.where((p) => p.isMine).toList();

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
    _notify();
  }

  /// OWNER ONLY: edit one of your own posts.
  static Future<void> update(
      String id, {
        required String name,
        required String animalType,
        required String age,
        required String sex,
        required String location,
        required String description,
        required String healthInfo,
        required String reasonForAdoption,
        required List<String> photos,
        required String contactPerson,
        required String contactPhone,
        required String contactEmail,
      }) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 500));

    final i = _pets.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Pet not found.');
    if (!_pets[i].isMine) {
      throw StateError('You can only edit your own posts.');
    }

    _pets[i] = _pets[i].copyWith(
      name: name,
      animalType: animalType,
      age: age,
      sex: sex,
      location: location,
      description: description,
      healthInfo: healthInfo,
      reasonForAdoption: reasonForAdoption,
      photos: photos,
      contactPerson: contactPerson,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
    );
    _notify();
  }

  /// OWNER ONLY: remove one of your own posts from the Adoption Board.
  static Future<void> remove(String id) async {
    // Simulates a network call.
    await Future.delayed(const Duration(milliseconds: 300));

    final i = _pets.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Pet not found.');
    if (!_pets[i].isMine) {
      throw StateError('You can only remove your own posts.');
    }

    _pets.removeAt(i);
    _notify();
  }
}
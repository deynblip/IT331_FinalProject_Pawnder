import 'package:flutter/material.dart';

import '../models/adoption_pet.dart';
import '../utils/app_colors.dart';
import 'adopt_pet_photo.dart';

/// One pet card in the Adoption Bulletin grid.
class AdoptionPetCard extends StatelessWidget {
  final AdoptionPet pet;
  final VoidCallback onViewDetails;

  const AdoptionPetCard({
    super.key,
    required this.pet,
    required this.onViewDetails,
  });

  Widget _photo() {
    final fallback = Container(
      color: const Color(0xFFE6E9EF),
      child: const Center(
        child: Icon(Icons.pets, size: 40, color: Color(0xFF8A8F98)),
      ),
    );

    final path = pet.coverPhoto;
    if (path == null) return fallback;

    return PetPhoto(path: path, fallback: fallback);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onViewDetails,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E5EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(width: double.infinity, child: _photo()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pet.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kHintGray, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onViewDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
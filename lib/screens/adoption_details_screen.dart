import 'package:flutter/material.dart';

import '../services/application_service.dart';
import 'adoption_application_screen.dart';
import '../models/adoption_pet.dart';
import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import '../widgets/adopt_pet_photo.dart';
import '../widgets/pet_source_tag.dart';
import '../widgets/rescuer_badge.dart';
import '../models/content_report.dart';
import '../widgets/report_content_dialog.dart';
import '../utils/responsive.dart';
import '../widgets/pet_contact_buttons.dart';

class AdoptionDetailsScreen extends StatelessWidget {
  final AdoptionPet pet;

  const AdoptionDetailsScreen({super.key, required this.pet});

  void _showHealthInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(context.hPad, 24, context.hPad, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Information',
              style: TextStyle(
                color: kNavy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pet.healthInfoOrDefault,
              style: const TextStyle(color: kNavy, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Opens the Adoption Application form (one application per pet).
  Future<void> _apply(BuildContext context) async {
    if (ApplicationService.hasApplied(pet.id)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('You already applied for this pet.')),
        );
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdoptionApplicationScreen(pet: pet),
      ),
    );
  }

  Widget _infoItem(IconData icon, String value) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(icon, color: kBlue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kNavy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(context.hPad, 12, context.hPad, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: kBlue,
                          ),
                        ),
                        const Text(
                          'Details',
                          style: TextStyle(
                            color: kNavy,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        // Report button (not shown on your own post)
                        if (!pet.isMine) ...[
                          const Spacer(),
                          IconButton(
                            tooltip: 'Report this post',
                            icon: const Icon(
                              Icons.flag_outlined,
                              color: ReportColors.grey,
                            ),
                            onPressed: () => showReportContentDialog(
                              context,
                              target: ReportTarget.adoptionPost,
                              targetId: pet.id,
                              targetTitle: pet.name,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Photo(s). Dots appear only when there is more than 1 photo.
                    _PetPhotos(photos: pet.photos),
                    const SizedBox(height: 16),

                    // Name, location, Health Info badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PetSourceTag(source: pet.source),
                              const SizedBox(height: 6),
                              // "Rescued by [Organization]" (Verified Rescuer posts)
                              if (pet.rescuedBy != null) ...[
                                RescuedByTag(organization: pet.rescuedBy!),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                pet.name.toUpperCase(),
                                style: const TextStyle(
                                  color: kNavy,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: ReportColors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      pet.location,
                                      style: const TextStyle(
                                        color: ReportColors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showHealthInfo(context),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: ReportColors.red,
                                  size: 32,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Health Info',
                                  style: TextStyle(
                                    color: ReportColors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age, Sex, Animal Type
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8D6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _infoItem(Icons.cake_outlined, pet.age),
                          _infoItem(
                            pet.sex == 'Female' ? Icons.female : Icons.male,
                            pet.sex,
                          ),
                          _infoItem(Icons.pets, pet.animalType),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Poster + contact icons (disabled until screening is passed)
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFFFFE8D6),
                          child: Icon(
                            Icons.person,
                            color: ReportColors.grey,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.posterName,
                                style: const TextStyle(
                                  color: kNavy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Pet Owner',
                                style: TextStyle(
                                  color: ReportColors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PetContactButtons(pet: pet),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // About
                    Text(
                      'ABOUT ${pet.name.toUpperCase()}',
                      style: const TextStyle(
                        color: kNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pet.descriptionOrDefault,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(color: kNavy, fontSize: 16),
                    ),
                    if (pet.reasonForAdoption.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        pet.source.reasonLabel.toUpperCase(),
                        style: const TextStyle(
                          color: kNavy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pet.reasonForAdoption,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(color: kNavy, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Hidden on your own post
            if (!pet.isMine)
              Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _apply(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply for Adoption',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Photo area. One photo = just the image. 2+ photos = swipeable with dots.
class _PetPhotos extends StatefulWidget {
  final List<String> photos;

  const _PetPhotos({required this.photos});

  @override
  State<_PetPhotos> createState() => _PetPhotosState();
}

class _PetPhotosState extends State<_PetPhotos> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFFFE8D6),
      child: const Center(
        child: Icon(Icons.pets, size: 48, color: ReportColors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: Stack(
          children: [
            if (photos.isEmpty)
              Positioned.fill(child: _fallback())
            else
              PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => PetPhoto(path: photos[i], fallback: _fallback()),
              ),
            if (photos.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (i) {
                    final active = i == _index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 10 : 8,
                      height: active ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? kBlue : Colors.white70,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
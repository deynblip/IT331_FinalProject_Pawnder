import 'package:flutter/material.dart';

import '../models/adoption_application.dart';
import '../services/adoption_service.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';
import '../utils/application_style.dart';
import '../utils/report_style.dart';
import '../widgets/adopt_pet_photo.dart';
import '../widgets/status_chip.dart';
import 'application_details_screen.dart';
import '../utils/responsive.dart';

/// Applications submitted by the logged-in user
/// (Profile > My Activity > Adoption Applications).
class MyApplicationsScreen extends StatelessWidget {
  /// Called after this screen closes, to switch to the Adopt tab.
  final VoidCallback? onBrowseAdoptions;

  const MyApplicationsScreen({super.key, this.onBrowseAdoptions});

  void _browse(BuildContext context) {
    Navigator.pop(context);
    onBrowseAdoptions?.call();
  }

  Widget _browseButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _browse(context),
      icon: const Icon(Icons.pets, size: 18),
      label: const Text('Browse Adoption Board'),
      style: ElevatedButton.styleFrom(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.hPad),
          // Rebuilds by itself when an application is added or changed.
          child: ValueListenableBuilder<int>(
            valueListenable: ApplicationService.changes,
            builder: (context, _, _) {
              final items = ApplicationService.forCurrentUser();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: kBlue),
                      ),
                      const Expanded(
                        child: Text(
                          'My Applications',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: kNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text(
                        items.length == 1
                            ? '1 application submitted'
                            : '${items.length} applications submitted',
                        style: const TextStyle(color: kHintGray),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pets,
                              size: 48, color: kHintGray),
                          const SizedBox(height: 12),
                          const Text(
                            "You haven't submitted any adoption "
                                'applications yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kHintGray),
                          ),
                          const SizedBox(height: 20),
                          _browseButton(context),
                        ],
                      ),
                    )
                        : ListView.builder(
                      // +1 = the Browse button at the end of the list
                      itemCount: items.length + 1,
                      itemBuilder: (_, i) {
                        if (i == items.length) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: _browseButton(context)),
                          );
                        }
                        return _ApplicationCard(
                          application: items[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApplicationDetailsScreen(
                                application: items[i],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final AdoptionApplication application;
  final VoidCallback onTap;

  const _ApplicationCard({required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pet = AdoptionService.byId(application.petId);
    final photo = pet?.coverPhoto;
    final subtitle = [
      if (pet != null) pet.animalType,
      'Applied ${application.dateText}',
    ].join('  ·  ');

    final placeholder = Container(
      color: const Color(0xFFFFE8D6),
      child: const Center(
        child: Icon(Icons.pets, size: 30, color: Color(0xFF8A746C)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF5DEC8)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14C4531F), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: photo == null
                      ? placeholder
                      : PetPhoto(path: photo, fallback: placeholder),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      label: application.status.label,
                      color: applicationStatusColor(application.status),
                      outlined: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      application.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReportColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: ReportColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ReportColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
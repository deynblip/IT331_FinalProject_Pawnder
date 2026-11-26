import 'package:flutter/material.dart';

import '../models/adoption_application.dart';
import '../models/adoption_pet.dart';
import '../services/adoption_service.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';
import '../utils/application_style.dart';
import '../widgets/adopt_pet_photo.dart';
import '../widgets/refreshing_builder.dart';
import '../widgets/status_chip.dart';
import 'adoption_details_screen.dart';
import 'owner_application_screen.dart';
import 'post_pet_screen.dart';
import '../utils/responsive.dart';

class MyPostsScreen extends StatelessWidget {
  final String posterName;

  const MyPostsScreen({super.key, required this.posterName});

  void _openPost(BuildContext context, AdoptionPet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdoptionDetailsScreen(pet: pet, showOwnerActions: true),
      ),
    );
  }

  void _openApplication(BuildContext context, AdoptionApplication a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerApplicationScreen(application: a),
      ),
    );
  }

  Widget _sectionTitle(String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: kNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null)
            Text(subtitle, style: TextStyle(color: kHintGray)),
        ],
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
          // Rebuilds by itself when a post or an application changes.
          child: RefreshingBuilder(
            listenable: Listenable.merge([
              AdoptionService.changes,
              ApplicationService.changes,
            ]),
            onRefresh: () async {
              await Future.wait([
                AdoptionService.load(),
                ApplicationService.refresh(),
              ]);
            },
            builder: (context, _) {
              final pets = AdoptionService.mine;
              final requests = ApplicationService.forMyPets();
              final waiting = requests
                  .where((a) => a.status == ApplicationStatus.forwardedToOwner)
                  .toList();
              final decided = requests
                  .where((a) => a.status != ApplicationStatus.forwardedToOwner)
                  .toList();

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
                      Expanded(
                        child: Text(
                          'My Adoption Posts',
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
                  if (pets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text(
                        pets.length == 1 ? '1 post' : '${pets.length} posts',
                        style: TextStyle(color: kHintGray),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: pets.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volunteer_activism_outlined,
                              size: 48, color: kHintGray),
                          const SizedBox(height: 12),
                          Text(
                            "You haven't posted any pets for "
                                'adoption yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kHintGray),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostPetScreen(
                                    posterName: posterName),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Post a Pet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView(
                      children: [
                        if (waiting.isNotEmpty) ...[
                          _sectionTitle(
                            'Needs your decision',
                            subtitle: 'Screened by the admin and '
                                'forwarded to you.',
                          ),
                          ...waiting.map(
                                (a) => _RequestCard(
                              application: a,
                              onTap: () => _openApplication(context, a),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _sectionTitle('My Posts'),
                        ...pets.map(
                              (p) => _PetPostCard(
                            pet: p,
                            waitingCount: waiting
                                .where((a) => a.petId == p.id)
                                .length,
                            onTap: () => _openPost(context, p),
                          ),
                        ),
                        if (decided.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _sectionTitle('Decided'),
                          ...decided.map(
                                (a) => _RequestCard(
                              application: a,
                              onTap: () => _openApplication(context, a),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
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

// ------------------------------------------------------------ Shared bits

Color get _kBorder => kCardBorder;

BoxDecoration _cardDecoration() => BoxDecoration(
  color: kCardColor,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: _kBorder),
  boxShadow: const [
    BoxShadow(
        color: Color(0x14C4531F), blurRadius: 10, offset: Offset(0, 3)),
  ],
);

Widget _petThumb(String? photo) {
  final placeholder = Container(
    color: kPeach,
    child: const Center(
      child: Icon(Icons.pets, size: 30, color: Color(0xFF8A746C)),
    ),
  );
  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 76,
      height: 76,
      child: photo == null
          ? placeholder
          : PetPhoto(path: photo, fallback: placeholder),
    ),
  );
}

// -------------------------------------------------------------- Pet post

class _PetPostCard extends StatelessWidget {
  final AdoptionPet pet;
  final int waitingCount;
  final VoidCallback onTap;

  const _PetPostCard({
    required this.pet,
    required this.waitingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _petThumb(pet.coverPhoto),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${pet.animalType}  ·  ${pet.summary}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: kHintGray, fontSize: 13),
                    ),
                    Text(
                      pet.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: kHintGray, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(
                      label: pet.status.label,
                      color: pet.status == PostStatus.approved
                          ? const Color(0xFF4CAF6E)
                          : pet.status == PostStatus.rejected
                          ? const Color(0xFFE04F4F)
                          : const Color(0xFFE0A800),
                      fontSize: 11,
                    ),
                    if (waitingCount > 0) ...[
                      const SizedBox(height: 6),
                      StatusChip(
                        label: waitingCount == 1
                            ? '1 awaiting your decision'
                            : '$waitingCount awaiting your decision',
                        color: kBlue,
                        outlined: true,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: kHintGray),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ Application card

class _RequestCard extends StatelessWidget {
  final AdoptionApplication application;
  final VoidCallback onTap;

  const _RequestCard({required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pet = AdoptionService.byId(application.petId);
    final waiting =
        application.status == ApplicationStatus.forwardedToOwner;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _petThumb(pet?.coverPhoto),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      label: waiting
                          ? 'Needs your decision'
                          : application.status.label,
                      color: waiting
                          ? kBlue
                          : applicationStatusColor(application.status),
                      outlined: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      application.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'For ${application.petName}  ·  ${application.dateText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: kHintGray, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: kHintGray),
            ],
          ),
        ),
      ),
    );
  }
}
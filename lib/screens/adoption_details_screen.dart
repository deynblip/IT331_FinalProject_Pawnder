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
import '../services/adoption_service.dart';
import '../widgets/post_actions.dart';

class AdoptionDetailsScreen extends StatefulWidget {
  final AdoptionPet pet;

  /// True only when opened from Profile > My Adoption Posts. Then the review
  /// status and the Edit / Remove buttons are shown (instead of Apply).
  final bool showOwnerActions;

  const AdoptionDetailsScreen({
    super.key,
    required this.pet,
    this.showOwnerActions = false,
  });

  @override
  State<AdoptionDetailsScreen> createState() => _AdoptionDetailsScreenState();
}

class _AdoptionDetailsScreenState extends State<AdoptionDetailsScreen> {
  /// Always the latest version of the pet (it changes after an edit).
  AdoptionPet get pet => AdoptionService.byId(widget.pet.id) ?? widget.pet;

  @override
  void initState() {
    super.initState();
    AdoptionService.changes.addListener(_onChanged);
  }

  @override
  void dispose() {
    AdoptionService.changes.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _remove(BuildContext context) async {
    final removed = await removeMyPost(context, pet);
    if (removed && context.mounted) Navigator.pop(context);
  }

  Widget _ownerBar(BuildContext context) {
    final bool rejected = pet.status == PostStatus.rejected;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => editMyPost(context, pet),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(rejected ? 'Resubmit' : 'Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kBlue,
                side: const BorderSide(color: kBlue),
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _remove(context),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

                    // Owner only: is the post Pending, Approved or Rejected?
                    if (widget.showOwnerActions) ...[
                      PostReviewNote(pet: pet),
                      const SizedBox(height: 12),
                    ],

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

            // Owner opened it from My Adoption Posts: Edit / Remove
            if (widget.showOwnerActions && pet.isMine) _ownerBar(context),

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

  /// Full-screen na photos: swipe para sa susunod, pinch para mag-zoom.
  void _openViewer(int start) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PetPhotoViewer(photos: widget.photos, initialIndex: start),
      ),
    );
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
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openViewer(i),
                  child: PetPhoto(path: photos[i], fallback: _fallback()),
                ),
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

/// Full-screen viewer. Swipe to change photo; pinch to zoom (swiping is
/// paused while zoomed in so panning the photo doesn't change the page).
class _PetPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PetPhotoViewer({required this.photos, required this.initialIndex});

  @override
  State<_PetPhotoViewer> createState() => _PetPhotoViewerState();
}

class _PetPhotoViewerState extends State<_PetPhotoViewer> {
  late final PageController _controller =
  PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: photos.length > 1
            ? Text('${_index + 1} / ${photos.length}',
            style: const TextStyle(fontSize: 16))
            : null,
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: photos.length,
        physics: _zoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: (i) => setState(() {
          _index = i;
          _zoomed = false;
        }),
        itemBuilder: (_, i) => _ZoomablePhoto(
          path: photos[i],
          onZoomChanged: (z) {
            if (z != _zoomed) setState(() => _zoomed = z);
          },
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  final String path;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePhoto({required this.path, required this.onZoomChanged});

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final TransformationController _tc = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final z = _tc.value.getMaxScaleOnAxis() > 1.02;
      if (z != _zoomed) {
        setState(() => _zoomed = z);
        widget.onZoomChanged(z);
      }
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _tc,
      minScale: 1,
      maxScale: 5,
      panEnabled: _zoomed,
      child: SizedBox.expand(
        child: PetPhoto(
          path: widget.path,
          fit: BoxFit.contain,
          fallback: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 48, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
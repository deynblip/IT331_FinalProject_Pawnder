import 'dart:async';

import 'package:flutter/material.dart';

import '../services/adoption_service.dart';
import 'post_pet_screen.dart';
import '../models/adoption_pet.dart';
import '../utils/app_colors.dart';
import '../widgets/adopt_pet_card.dart';
import 'adoption_details_screen.dart';
import '../utils/responsive.dart';

class AdoptPage extends StatefulWidget {
  final String posterName;

  const AdoptPage({super.key, this.posterName = 'Dane Angela'});

  @override
  State<AdoptPage> createState() => _AdoptPageState();
}

class _AdoptPageState extends State<AdoptPage> {
  static const List<String> _filters = ['All Pets', 'Dogs', 'Cats'];
  String _selected = 'All Pets';

  // Second filter row: where the pet comes from (null = All).
  PetSource? _source;

  // Quietly reloads the posts so a newly approved post shows up by itself.
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    AdoptionService.load();
    _poll = Timer.periodic(
      const Duration(seconds: 20),
          (_) => AdoptionService.load(),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  // Only ADMIN-APPROVED posts are shown here. Read fresh on every build.
  // Rescued Strays are always listed first (they are the priority).
  List<AdoptionPet> get _visible {
    var pets = AdoptionService.approved;
    switch (_selected) {
      case 'Dogs':
        pets = pets.where((p) => p.animalType == 'Dog').toList();
      case 'Cats':
        pets = pets.where((p) => p.animalType == 'Cat').toList();
    }
    if (_source != null) {
      pets = pets.where((p) => p.source == _source).toList();
    }
    // Stable sort: rescued strays first, the original order is kept otherwise.
    final rescued =
    pets.where((p) => p.source == PetSource.rescuedStray).toList();
    final rehoming = pets.where((p) => p.source != PetSource.rescuedStray);
    return [...rescued, ...rehoming];
  }

  Widget _sourceChip(String label, PetSource? value) {
    final selected = _source == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        selectedColor: kNavy,
        backgroundColor: kPeach,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: selected ? Colors.white : kNavy,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _source = value),
      ),
    );
  }

  void _openDetails(AdoptionPet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdoptionDetailsScreen(pet: pet)),
    );
  }

  // Opens the Post a Pet form. It returns true when a pet was published.
  Future<void> _postPet() async {
    final published = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PostPetScreen(posterName: widget.posterName),
      ),
    );

    // The new post is PENDING, so it is not on this board until an admin
    // approves it (see "My Adoption Posts" for its status).
    if (published == true && mounted) {
      setState(() => _selected = 'All Pets');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdoptionService.changes,
      builder: (context, _, _) => _buildBoard(),
    );
  }

  Widget _buildBoard() {
    final items = _visible;

    return Scaffold(
      backgroundColor: kCream,
      floatingActionButton: FloatingActionButton(
        onPressed: _postPet,
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adopt a Pet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _filters.map((f) {
                final selected = _selected == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: kBlue,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: kBlue),
                  labelStyle: TextStyle(color: selected ? Colors.white : kBlue),
                  onSelected: (_) => setState(() => _selected = f),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sourceChip('All', null),
                  _sourceChip('Rescued Strays', PetSource.rescuedStray),
                  _sourceChip('Rehoming', PetSource.rehoming),
                ],
              ),
            ),
            const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: kBlue,
            onRefresh: AdoptionService.load,
            child: items.isEmpty
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No pets available right now.',
                    style: TextStyle(color: kHintGray),
                  ),
                ),
              ],
            )
                : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              // extra bottom space so the + button doesn't cover the last row
              padding: const EdgeInsets.only(bottom: 88),
                itemCount: items.length,
                // 2 columns on phones, 3 on wider screens.
                gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.70,
                ),
                  itemBuilder: (_, i) => AdoptionPetCard(
                    pet: items[i],
                    onViewDetails: () => _openDetails(items[i]),
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
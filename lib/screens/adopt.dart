import 'package:flutter/material.dart';

import '../services/adoption_service.dart';
import 'post_pet_screen.dart';
import '../models/adoption_pet.dart';
import '../utils/app_colors.dart';
import '../widgets/adopt_pet_card.dart';
import 'adoption_details_screen.dart';

class AdoptPage extends StatefulWidget {
  final String posterName;

  const AdoptPage({super.key, this.posterName = 'Dane Angela'});

  @override
  State<AdoptPage> createState() => _AdoptPageState();
}

class _AdoptPageState extends State<AdoptPage> {
  static const List<String> _filters = ['Dogs', 'Cats', 'All Pets'];
  String _selected = 'All Pets';

  // TEMP: in-memory data. Will be replaced by data from the backend.
  List<AdoptionPet> _pets = AdoptionService.all;

  List<AdoptionPet> get _visible {
    switch (_selected) {
      case 'Dogs':
        return _pets.where((p) => p.animalType == 'Dog').toList();
      case 'Cats':
        return _pets.where((p) => p.animalType == 'Cat').toList();
      default:
        return _pets;
    }
  }

  void _openDetails(AdoptionPet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdoptionDetailsScreen(pet: pet)),
    );
  }

  // TEMP: the Post a Pet form is built in the next task.
  // Opens the Post a Pet form. It returns true when a pet was published.
  Future<void> _postPet() async {
    final published = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PostPetScreen(posterName: widget.posterName),
      ),
    );

    if (published == true && mounted) {
      setState(() {
        _pets = AdoptionService.all; // reload, newest post is first
        _selected = 'All Pets'; // make sure the new post is visible
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _postPet,
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                child: Text(
                  'No pets available right now.',
                  style: TextStyle(color: kHintGray),
                ),
              )
                  : GridView.builder(
                // extra bottom space so the + button doesn't cover the last row
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: items.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
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
          ],
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/adoption_application.dart';
import '../models/adoption_pet.dart';
import '../services/adoption_service.dart';
import '../services/application_service.dart';
import '../utils/app_colors.dart';

/// The mail and phone icons next to the pet owner.
/// They work only after the user's application passed admin screening
/// (Forwarded or Approved). The owner always sees their own details.
/// The owner's details come from the database, so this reloads them while
/// the screen is open and unlocks the icons by itself.
class PetContactButtons extends StatefulWidget {
  final AdoptionPet pet;

  const PetContactButtons({super.key, required this.pet});

  @override
  State<PetContactButtons> createState() => _PetContactButtonsState();
}

class _PetContactButtonsState extends State<PetContactButtons> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _reload();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _reload());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _reload() {
    AdoptionService.load();
    ApplicationService.load();
  }

  AdoptionApplication? _myApplication() {
    for (final a in ApplicationService.forCurrentUser()) {
      if (a.petId == widget.pet.id) return a;
    }
    return null;
  }

  Future<void> _open(Uri uri, String copyText, String what) async {
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (ok || !mounted) return;
    // No app can open it: copy it so the user can still use it.
    await Clipboard.setData(ClipboardData(text: copyText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what copied: $copyText')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AdoptionService.changes,
        ApplicationService.changes,
      ]),
      builder: (context, _) {
        final AdoptionPet pet = AdoptionService.byId(widget.pet.id) ?? widget.pet;
        final AdoptionApplication? app = _myApplication();

        final bool unlocked = pet.isMine ||
            (app != null &&
                (app.status == ApplicationStatus.forwardedToOwner ||
                    app.status == ApplicationStatus.approved));

        final String email = pet.contactEmail.trim();
        final String phone = pet.contactPhone.trim();

        final String hint = !unlocked
            ? 'Available after your application passes screening'
            : (email.isEmpty && phone.isEmpty)
            ? 'Loading the owner\'s contact details...'
            : '';

        final Widget buttons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: unlocked && email.isNotEmpty ? 'Email $email' : null,
              onPressed: unlocked && email.isNotEmpty
                  ? () => _open(Uri(scheme: 'mailto', path: email), email, 'Email')
                  : null,
              icon: Icon(
                Icons.mail_outline,
                color: unlocked && email.isNotEmpty ? kBlue : null,
              ),
            ),
            IconButton(
              tooltip: unlocked && phone.isNotEmpty ? 'Call $phone' : null,
              onPressed: unlocked && phone.isNotEmpty
                  ? () => _open(Uri(scheme: 'tel', path: phone), phone, 'Phone number')
                  : null,
              icon: Icon(
                Icons.phone_outlined,
                color: unlocked && phone.isNotEmpty ? kBlue : null,
              ),
            ),
          ],
        );

        if (hint.isEmpty) return buttons;
        return Tooltip(
          message: hint,
          triggerMode: TooltipTriggerMode.tap,
          child: buttons,
        );
      },
    );
  }
}
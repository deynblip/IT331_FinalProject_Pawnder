import 'package:flutter/material.dart';

import '../models/rescuer_application.dart';
import '../services/auth_service.dart';
import '../services/rescuer_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/rescuer_form.dart';
import '../utils/responsive.dart';

/// Profile > Apply as Verified Rescuer (also used to apply again after a
/// rejection). [previous] pre-fills the form.
class RescuerApplicationScreen extends StatefulWidget {
  final RescuerApplication? previous;

  const RescuerApplicationScreen({super.key, this.previous});

  @override
  State<RescuerApplicationScreen> createState() =>
      _RescuerApplicationScreenState();
}

class _RescuerApplicationScreenState extends State<RescuerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final RescuerFormControllers _c = RescuerFormControllers();

  @override
  void initState() {
    super.initState();
    final prev = widget.previous;
    if (prev != null) _c.prefill(prev);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;

    final email = AuthService.currentEmail;
    if (email == null) {
      showMessage(context, 'Please log in again.');
      return;
    }

    setState(() => _busy = true);
    final String? error = await RescuerService.submitToDatabase(
      organization: _c.organization.text,
      roleInOrg: _c.roleInOrg.text,
      contactPerson: _c.contactPerson.text,
      contactNumber: _c.contactNumber.text,
      officialPage: _c.officialPage.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      showMessage(context, error);
      return;
    }

    showMessage(context, 'Application sent! An admin will review it.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Apply as Verified Rescuer',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const RescuerPendingNote(),
                const SizedBox(height: 18),
                RescuerFormFields(controllers: _c),
                const SizedBox(height: 22),
                AuthButton(
                  text: _busy ? 'Sending...' : 'Submit Application',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
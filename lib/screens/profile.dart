import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../models/rescuer_application.dart';
import '../utils/app_colors.dart';
import 'my_reports_screen.dart';
import 'my_responses_screen.dart';
import '../services/adoption_service.dart';
import '../services/application_service.dart';
import '../services/rescuer_service.dart';
import '../services/response_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/rescuer_badge.dart';
import 'my_applications_screen.dart';
import 'my_posts_screen.dart';
import 'rescuer_application_screen.dart';
import '../utils/responsive.dart';

class ProfilePage extends StatefulWidget {
  final String name;

  final VoidCallback? onBrowseAdoptions;

  const ProfilePage({super.key, required this.name, this.onBrowseAdoptions});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // My Reports count and Rescue Record come from the database.
    ReportService.ensureLoaded();
    ReportService.loadMyResponses(); // My Responses count
    ResponseService.loadMe();
    RescuerService.loadMine(); // Pending / Verified / Not approved status
    ReportService.changes.addListener(_redraw);
    ResponseService.changes.addListener(_onResponsesChanged);
  }

  @override
  void dispose() {
    ReportService.changes.removeListener(_redraw);
    ResponseService.changes.removeListener(_onResponsesChanged);
    super.dispose();
  }

  // Redraws the page when reports or the Rescue Record change.
  void _redraw() {
    if (mounted) setState(() {});
  }

  // After responding, checking in or withdrawing: refresh My Responses too.
  void _onResponsesChanged() {
    ReportService.loadMyResponses();
    _redraw();
  }

  // Profile photo (saved in the database). Tap to change or remove it.
  Widget _avatar() {
    return GestureDetector(
      onTap: () => showAvatarOptions(context),
      child: ProfileAvatar(
        size: 120,
        background: kPeach,
        iconColor: kNavy,
        borderColor: kNavy,
        borderWidth: 4,
        showEditBadge: true,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // VERIFIED RESCUER SECTION
  // ---------------------------------------------------------------------

  Widget _rescuerCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14C4531F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: kNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: kHintGray, fontSize: 13, height: 1.4),
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openRescuerForm(RescuerApplication? previous) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RescuerApplicationScreen(previous: previous),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // RESCUE RECORD (accountability + trust level)
  // ---------------------------------------------------------------------

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: kNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: kHintGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _recordCard() {
    return ListenableBuilder(
      listenable: ResponseService.changes,
      builder: (context, _) {
        final email = AuthService.currentEmail;
        if (email == null) return const SizedBox.shrink();
        final stats = ResponseService.myStats;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kCardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14C4531F),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Rescue Record',
                      style: TextStyle(
                        color: kNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3DE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stats.trustLevel.label,
                      style: const TextStyle(
                        color: Color(0xFF3B6D11),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statBox('${stats.rescues}', 'Completed\nrescues'),
                  _statBox('${stats.cancelled}', 'Cancelled\nresponses'),
                  _statBox(stats.completionRate, 'Completion\nrate'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rescuerSection() {
    return ListenableBuilder(
      listenable: RescuerService.changes,
      builder: (context, _) {
        final app = RescuerService.currentApplication;
        final status = RescuerService.currentStatus;

        switch (status) {
          case RescuerStatus.verified:
            return Center(
              child: RescuerBadge(organization: app!.organization),
            );

          case RescuerStatus.pending:
            return _rescuerCard(
              icon: Icons.hourglass_top,
              color: const Color(0xFFE9A23B),
              title: 'Rescuer status: Pending Verification',
              message: 'An admin is confirming your application with '
                  '${app!.organization}. You can keep using Pawnder as a '
                  'regular user while you wait.',
            );

          case RescuerStatus.rejected:
            final bool badgeRemoved =
            (app!.rejectionReason ?? '').startsWith('Badge removed:');
            final String reason = (app.rejectionReason ?? '-')
                .replaceFirst('Badge removed:', '')
                .trim();
            return _rescuerCard(
              icon: badgeRemoved
                  ? Icons.remove_moderator_outlined
                  : Icons.cancel_outlined,
              color: const Color(0xFFE04F4F),
              title: badgeRemoved
                  ? 'Verified Rescuer badge removed'
                  : 'Rescuer application not approved',
              message: 'Reason: $reason\n'
                  'You are now a regular user. You can apply again.',
              buttonText: 'Apply Again',
              onPressed: () => _openRescuerForm(app),
            );

          case RescuerStatus.none:
            {
              final email = AuthService.currentEmail;
              final trusted = email != null &&
                  ResponseService.myStats.trustLevel ==
                      TrustLevel.trustedHelper;
              if (trusted) {
                return _rescuerCard(
                  icon: Icons.workspace_premium_outlined,
                  color: const Color(0xFF4CAF6E),
                  title: 'You are a Trusted Helper!',
                  message: 'Thank you for all your rescues. You can now apply '
                      'to become a Verified Rescuer, even without an '
                      'organization.',
                  buttonText: 'Apply as Verified Rescuer',
                  onPressed: () => _openRescuerForm(null),
                );
              }
              return _rescuerCard(
                icon: Icons.verified_user_outlined,
                color: kBlue,
                title: 'Are you part of a rescue group?',
                message: 'Rescue organizations, vets and LGU animal welfare '
                    'offices can apply to become Verified Rescuers.',
                buttonText: 'Apply as Verified Rescuer',
                onPressed: () => _openRescuerForm(null),
              );
            }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsCount = ReportService.mine.length;
    final responsesCount = ReportService.respondedByMe.length;
    final applicationsCount = ApplicationService.forCurrentUser().length;
    final postsCount = AdoptionService.mine.length;
    final displayName =
    widget.name.trim().isNotEmpty ? widget.name : 'Pawnder User';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(context.hPad, 32, context.hPad, 24),
      child: Column(
        children: [
          _avatar(),

          const SizedBox(height: 14),

          Text(
            displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kNavy,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),

          // Email of the account, under the name
          if ((AuthService.currentEmail ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              AuthService.currentEmail!,
              textAlign: TextAlign.center,
              style: TextStyle(color: kHintGray, fontSize: 14),
            ),
          ],

          const SizedBox(height: 12),

          // Verified Rescuer badge, or the apply / pending / rejected card
          _rescuerSection(),

          const SizedBox(height: 16),

          // Completed / cancelled responses and trust level
          _recordCard(),

          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 6),
              child: Text(
                'My Activity',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kCardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14C4531F),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _activityRow(
                  icon: Icons.assignment_outlined,
                  title: 'My Reports',
                  count: reportsCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                  ),
                ),
                Divider(height: 1, color: kCardBorder),
                _activityRow(
                  icon: Icons.directions_run,
                  title: 'My Responses',
                  count: responsesCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyResponsesScreen()),
                  ),
                ),
                Divider(height: 1, color: kCardBorder),
                _activityRow(
                  icon: Icons.pets,
                  title: 'Adoption Applications',
                  count: applicationsCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyApplicationsScreen(
                        onBrowseAdoptions: widget.onBrowseAdoptions,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {}); // refresh the count
                  }),
                ),
                Divider(height: 1, color: kCardBorder),
                _activityRow(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'My Adoption Posts',
                  count: postsCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyPostsScreen(posterName: displayName),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {}); // refresh the count
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: kNavy, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: kNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(color: kHintGray, fontSize: 17),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: kHintGray),
          ],
        ),
      ),
    );
  }
}
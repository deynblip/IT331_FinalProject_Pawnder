import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'report_service.dart';
import 'response_service.dart';
import 'rescuer_service.dart';
import 'adoption_service.dart';
import 'application_service.dart';
import 'content_report_service.dart';
import 'notification_service.dart';

// ===============================
// AUTH SERVICE (Supabase)
// ===============================
// Sign up, log in, log out, forgot password and change password, using
// Supabase Auth. Passwords are handled by Supabase (stored hashed); the app
// never saves them.
//
// Every account has a row in the `profiles` table (created automatically by
// the database on sign up) with the user's name and role (user / admin).
// Admins can only be assigned in the Supabase dashboard, never from the app.

/// An error with a message that can be shown to the user as-is.
class AuthFailure implements Exception {
  final String message;
  final bool emailNotConfirmed;

  const AuthFailure(this.message, {this.emailNotConfirmed = false});

  @override
  String toString() => message;
}

/// Result of checking the saved session when the app opens.
enum SessionStatus { none, ready, offline, restricted }

class AuthService {
  static SupabaseClient get _db => Supabase.instance.client;

  // TEMPORARY: the in-memory Verified Rescuer service still sends admin
  // notifications to this email. Removed when Verified Rescuers move to
  // Supabase (later batch).
  static const String adminEmail = 'admin@pawnder.com';

  // Details of the logged-in user, loaded from `profiles` after log in.
  static String? _name;
  static bool _isAdmin = false;
  static bool _isRestricted = false;
  static int _userCount = 0;

  // True only while someone is logged in and their profile is loaded.
  static bool _sessionActive = false;
  static bool get sessionActive => _sessionActive;

  // Names of accounts used on this device. TEMPORARY: lets the in-memory
  // services (reports, responses, rescuers) still show names until they
  // move to Supabase in the next batches.
  static final Map<String, String> _knownNames = {};

  // ---------------------------------------------------------------- Current user

  static User? get _user => _db.auth.currentUser;

  static String? get currentUserId => _user?.id;

  static String? get currentEmail => _user?.email?.toLowerCase();

  static String get currentName => _name ?? '';

  static bool get isCurrentAdmin => _user != null && _isAdmin;

  static bool get isCurrentRestricted => _isRestricted;

  /// Number of registered regular users (admin dashboard).
  static int get userCount => _userCount;

  static String? nameOf(String email) =>
      _knownNames[email.trim().toLowerCase()];

  // ---------------------------------------------------------------- Log in / out

  /// Logs in and loads the user's profile. Throws [AuthFailure].
  static Future<void> logIn(String email, String password) async {
    endSession(); // forget the previous account's data first
    await _run(() => _db.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    ));
    await _loadProfile();
    if (_isRestricted) {
      await signOut();
      throw const AuthFailure('Your account has been restricted.');
    }
    _sessionActive = true;
  }

  /// App start: checks the session saved on the phone.
  /// Only logs out when the SERVER says the session is invalid, the
  /// account was deleted, or it is restricted. No internet = offline.
  static Future<SessionStatus> restoreSession() async {
    if (_user == null) return SessionStatus.none;
    try {
      await _db.auth.getUser();
      await _fetchProfile();
    } on AuthException catch (e) {
      final String? s = e.statusCode;
      if (s == '401' || s == '403' || s == '404') {
        await signOut();
        return SessionStatus.none;
      }
      return SessionStatus.offline;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No profile row: the account was deleted.
        await signOut();
        return SessionStatus.none;
      }
      return SessionStatus.offline;
    } catch (e) {
      debugPrint('Restore session error: $e');
      return SessionStatus.offline;
    }

    if (_isRestricted) {
      await signOut();
      return SessionStatus.restricted;
    }
    _sessionActive = true;
    return SessionStatus.ready;
  }

  /// Clears everything remembered about the logged-in user (details and
  /// cached reports/stats) so the next account never sees old data.
  static void endSession() {
    _name = null;
    _isAdmin = false;
    _isRestricted = false;
    _userCount = 0;
    _sessionActive = false;
    ReportService.reset();
    ResponseService.reset();
    AdoptionService.reset();
    ApplicationService.reset();
    ContentReportService.reset();
    NotificationService.reset();
    RescuerService.reset();
  }

  static Future<void> signOut() async {
    endSession();
    try {
      await _db.auth.signOut();
    } catch (e) {
      // Still logged out on this phone even if the server can't be reached.
      debugPrint('Sign out error: $e');
    }
  }

  // ---------------------------------------------------------------- Sign up

  /// Creates an account. If [rescuerApplication] is given (Professional
  /// Rescuer), the database also saves a pending Verified Rescuer
  /// application. Keys: organization, role_in_org, contact_person,
  /// contact_number, official_page. Throws [AuthFailure].
  ///
  /// Returns true when the user must now enter the code that was emailed
  /// (Confirm email is ON in Supabase). Returns false when Confirm email is
  /// OFF: then the user is logged out and the app asks them to log in.
  static Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String>? rescuerApplication,
  }) async {
    final AuthResponse res = await _run(() => _db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        if (rescuerApplication != null)
          'rescuer_application': rescuerApplication,
      },
    ));

    // When the email is already used, Supabase may return a user with no
    // identities instead of an error.
    final List<UserIdentity>? identities = res.user?.identities;
    if (res.user != null && identities != null && identities.isEmpty) {
      throw const AuthFailure('An account with this email already exists.');
    }

    _knownNames[email.trim().toLowerCase()] = name.trim();

    // Confirm email ON: there is no session yet. The user enters the code.
    if (res.session == null) return true;

    // Confirm email OFF: log out, the app asks the user to log in.
    await signOut();
    return false;
  }

  /// Sign up, step 2: checks the code from the email. When it is right the
  /// email is verified and the user is logged in. Throws [AuthFailure].
  static Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    endSession(); // forget the previous account's data first
    await _run(() => _db.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: code.trim(),
    ));
    await _loadProfile();
    if (_isRestricted) {
      await signOut();
      throw const AuthFailure('Your account has been restricted.');
    }
    _sessionActive = true;
  }

  /// Sends a new verification code to the email.
  static Future<void> resendSignupCode(String email) async {
    await _run(() => _db.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    ));
  }

  // ---------------------------------------------------------------- Passwords

  /// Forgot password, step 1: emails a reset code to the user.
  /// For privacy, Supabase doesn't say whether the email has an account.
  static Future<void> sendPasswordResetCode(String email) async {
    await _run(() => _db.auth.resetPasswordForEmail(email.trim()));
  }

  /// Forgot password, step 2: checks the code from the email, then saves
  /// the new password. The user is logged out afterwards.
  static Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _run(() => _db.auth.verifyOTP(
      type: OtpType.recovery,
      email: email.trim(),
      token: code.trim(),
    ));
    await _run(() => _db.auth.updateUser(UserAttributes(password: newPassword)));
    await signOut();
  }

  /// Settings > Change Password. Checks the current password first.
  static Future<void> changePassword(
      String currentPassword,
      String newPassword,
      ) async {
    final String? email = currentEmail;
    if (email == null) throw const AuthFailure('Please log in first.');

    try {
      await _run(() => _db.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      ));
    } on AuthFailure catch (e) {
      if (e.message == _wrongLogin) {
        throw const AuthFailure('Your current password is incorrect.');
      }
      rethrow;
    }
    await _run(() => _db.auth.updateUser(UserAttributes(password: newPassword)));
  }

  // ---------------------------------------------------------------- Profile

  /// Loads the profile. Throws the raw error if it fails.
  static Future<void> _fetchProfile() async {
    final Map<String, dynamic> row = await _db
        .from('profiles')
        .select('full_name, role, is_restricted')
        .eq('id', currentUserId!)
        .single();

    _name = row['full_name'] as String?;
    _isAdmin = row['role'] == 'admin';
    _isRestricted = row['is_restricted'] == true;
    if (currentEmail != null && _name != null) {
      _knownNames[currentEmail!] = _name!;
    }
    if (_isAdmin) await refreshUserCount();
  }

  /// Used by Log In: logs out and shows a message if it fails.
  static Future<void> _loadProfile() async {
    try {
      await _fetchProfile();
    } catch (e) {
      debugPrint('Load profile error: $e');
      await signOut();
      throw AuthFailure(_isNetworkError(e)
          ? _noInternet
          : 'Could not load your account. Please try again.');
    }
  }

  /// Admins only: reloads the number of registered users.
  static Future<void> refreshUserCount() async {
    try {
      final dynamic counts = await _db.rpc('admin_dashboard_counts');
      _userCount = (counts['registered_users'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('User count error: $e');
    }
  }

  // ---------------------------------------------------------------- Errors

  static const String _wrongLogin = 'Incorrect email or password.';
  static const String _noInternet =
      'No internet connection. Please check your connection and try again.';

  /// Runs a Supabase call and turns its errors into friendly messages.
  static Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.code} ${e.statusCode} ${e.message}');
      throw AuthFailure(
        _friendly(e),
        emailNotConfirmed: e.code == 'email_not_confirmed',
      );
    } catch (e) {
      debugPrint('Auth error: $e');
      throw AuthFailure(_isNetworkError(e)
          ? _noInternet
          : 'Something went wrong. Please try again.');
    }
  }

  static String _friendly(AuthException e) {
    final String code = e.code ?? '';
    final String msg = e.message.toLowerCase();

    if (msg.contains('database error')) {
      return 'Could not create the account. Please check your details '
          'and try again.';
    }
    if (_isNetworkError(e) ||
        (e is AuthRetryableFetchException && e.statusCode == null)) {
      return _noInternet;
    }
    if (e is AuthRetryableFetchException) {
      return 'The server is busy right now. Please try again in a moment.';
    }
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return _wrongLogin;
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        msg.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    if (code == 'email_not_confirmed') {
      return 'Please confirm your email first.';
    }
    if (code == 'otp_expired' || msg.contains('token')) {
      return 'The code is wrong or has expired. Please request a new one.';
    }
    if (code == 'same_password') {
      return 'Your new password must be different from your current one.';
    }
    if (code == 'weak_password') {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (code.startsWith('over_') || e.statusCode == '429') {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (msg.contains('database error')) {
      return 'Could not create the account. Please check your details '
          'and try again.';
    }
    return e.message;
  }

  static bool _isNetworkError(Object e) {
    final String s = e.toString();
    return s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('ClientException') ||
        s.contains('Connection refused') ||
        s.contains('XMLHttpRequest');
  }
}
// ===============================
// TEMPORARY IN-MEMORY AUTH
// ===============================
// Accounts created on the Sign Up page are stored here so the Log In page
// can check them. This resets every time the app restarts.
// Replace with Firebase Auth or your own backend later.

class AuthService {
  // A ready-made admin account (temporary, for development).
  static const String adminEmail = 'admin@pawnder.com';
  static const String adminPassword = 'admin123';

  static final Map<String, _Account> _accounts = {
    adminEmail: _Account('Admin', adminPassword, isAdmin: true),
  };

  static String _key(String email) => email.trim().toLowerCase();

  static bool emailExists(String email) => _accounts.containsKey(_key(email));

  static void register(String name, String email, String password) {
    _accounts[_key(email)] = _Account(name.trim(), password);
  }

  static bool passwordMatches(String email, String password) {
    return _accounts[_key(email)]?.password == password;
  }

  static String? nameOf(String email) => _accounts[_key(email)]?.name;

  static bool isAdmin(String email) => _accounts[_key(email)]?.isAdmin ?? false;

  // Number of regular users (the admin account is not counted).
  static int get userCount =>
      _accounts.values.where((a) => !a.isAdmin).length;

  static void updatePassword(String email, String newPassword) {
    final old = _accounts[_key(email)];
    if (old == null) return;
    _accounts[_key(email)] =
        _Account(old.name, newPassword, isAdmin: old.isAdmin);
  }
}

class _Account {
  final String name;
  final String password;
  final bool isAdmin;
  _Account(this.name, this.password, {this.isAdmin = false});
}
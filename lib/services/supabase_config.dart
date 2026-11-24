// ===============================
// SUPABASE SETTINGS
// ===============================
// Where the app's database lives (Supabase project "pawnder").
//
// Both values are SAFE to keep in the app: the publishable key only lets
// the app talk to the database, and the database's security rules decide
// what each user can see or change.
//
// NEVER put the secret key (sb_secret_... / service_role) or the database
// password in the app or on GitHub.

class SupabaseConfig {
  static const String url = 'https://eihbsgdhdreelnxukiqe.supabase.co';

  static const String publishableKey =
      'sb_publishable_sE3GTACZNEHWPW3V9amNJA_iLKuziCG';
}
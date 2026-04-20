import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sing in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }
  // Sign up with email and password
Future<AuthResponse> signUpWithEmailPassword(String email, String password) {
    return _supabase.auth.signUp(email: email, password: password);
  }
  // Sign out
  Future<void> signOut() {
    return _supabase.auth.signOut();
  }
  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  Future<void> resetPassword(String email) {
    return _supabase.auth.resetPasswordForEmail(email);
  }
}


import 'package:my_pos/features/auth/domain/models/user_profile.dart';
import 'package:my_pos/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthRepository {
  // ─── Login ───
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      return await _getOrCreateProfile(response.user!);
    } on sb.AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Register ───
  Future<UserProfile> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'admin',
  }) async {
    try {
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      // Create profile
      await SupabaseService.table('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
      });

      return UserProfile(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
      );
    } on sb.AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Get Current Profile ───
  Future<UserProfile?> getCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      return await _getOrCreateProfile(user);
    } catch (_) {
      return null;
    }
  }

  // ─── Logout ───
  Future<void> logout() async {
    await SupabaseService.auth.signOut();
  }

  // ─── PIN Login ───
  Future<UserProfile?> loginWithPin(String pin) async {
    try {
      // NOTE: Requires RLS policy:
      // CREATE POLICY "Allow PIN search" ON profiles FOR SELECT TO anon, authenticated USING (pin IS NOT NULL);
      final response = await SupabaseService.table('profiles')
          .select()
          .eq('pin', pin)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('PIN Login failed. Please check your connection or try again later.');
    }
  }

  // ─── Update Profile ───
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await SupabaseService.table('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
    return profile;
  }

  // ─── Helper: Get or create profile from Supabase user ───
  Future<UserProfile> _getOrCreateProfile(sb.User user) async {
    try {
      // 1. Try to get existing profile
      final existing = await SupabaseService.table('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        return UserProfile.fromJson(existing);
      }

      // 2. Create if not exists
      final newProfile = {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            'New User',
        'role': 'admin',
        'created_at': DateTime.now().toIso8601String(),
      };

      final data = await SupabaseService.table('profiles')
          .insert(newProfile)
          .select()
          .maybeSingle();

      if (data == null) {
        throw Exception('Failed to create or retrieve profile');
      }

      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Authentication profile error: $e');
    }
  }
}

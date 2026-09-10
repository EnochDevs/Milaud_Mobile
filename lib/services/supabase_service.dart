import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // On web hot reload Supabase may already be initialized — check first
    try {
      Supabase.instance.client;
      _initialized = true;
      return;
    } catch (_) {
      // Not yet initialized, proceed normally
    }

    // FIX — was ".env". Netlify (and other static hosts) silently drop
    // dotfiles from what's actually deployed, so this asset 404'd on the
    // live site even though it built correctly locally — Supabase never
    // initialized there, which surfaced as every login/signup just
    // failing with a generic error. See pubspec.yaml's assets list.
    await dotenv.load(fileName: "app.env");

    await Supabase.initialize(
      url:     dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get userId => currentUser?.id;
}
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mismo backend Supabase del prototipo HTML: proyecto `ejobycpstnbzkjnlebrd`,
/// schema `la_vuelta` (compartido con otras apps de Pablo). Se reutiliza tal
/// cual — mismas tablas y funciones RPC `SECURITY DEFINER` — no se toca el schema.
class SupabaseService {
  SupabaseService._();

  static const String supabaseUrl = 'https://ejobycpstnbzkjnlebrd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqb2J5Y3BzdG5iemtqbmxlYnJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzODAyMzcsImV4cCI6MjA5OTk1NjIzN30.BHplkrJ8e3eADWsu17Wth24VJUW4b9csJWB2TTHLR9o';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  /// Cliente apuntando al schema `la_vuelta`, igual que el prototipo
  /// (`supabase.createClient(URL, KEY, { db: { schema: 'la_vuelta' } })`).
  static SupabaseClient get client => Supabase.instance.client;
  static SupabaseQueryBuilder from(String table) => client.schema('la_vuelta').from(table);
}

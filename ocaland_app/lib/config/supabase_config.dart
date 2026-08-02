/// Config del backend de Supabase compartido con el prototipo HTML.
///
/// Mismo proyecto y schema que `la-vuelta-multijugador-test.html`. La clave
/// "anon" es pública por diseño (Supabase la protege con RLS del lado del
/// servidor) — ya está expuesta hoy en el código fuente del sitio, así que
/// versionarla acá no agrega ninguna exposición nueva.
class SupabaseConfig {
  SupabaseConfig._();

  static const String projectRef = 'ejobycpstnbzkjnlebrd';
  static const String url = 'https://ejobycpstnbzkjnlebrd.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqb2J5Y3BzdG5iemtqbmxlYnJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzODAyMzcsImV4cCI6MjA5OTk1NjIzN30.BHplkrJ8e3eADWsu17Wth24VJUW4b9csJWB2TTHLR9o';

  /// Todas las tablas y funciones RPC del juego viven en este schema,
  /// compartido con otras apps de Pablo (ej. Charla) en el mismo proyecto.
  static const String schema = 'la_vuelta';
}

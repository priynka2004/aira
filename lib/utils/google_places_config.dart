/// Google Places API key, used by CityAutocompleteField for the
/// Artist Signup "Location" field.
///
/// HOW TO GET A KEY:
/// 1. Go to https://console.cloud.google.com/ → create/select a project.
/// 2. Enable "Places API" (APIs & Services → Library → search "Places API").
/// 3. Enable billing on the project (Google requires it, but Places
///    Autocomplete has a generous free monthly quota).
/// 4. APIs & Services → Credentials → Create Credentials → API key.
/// 5. Restrict the key: Application restrictions → Android/iOS apps
///    (add your package name + SHA-1 for Android), and under API
///    restrictions, limit it to just "Places API".
/// 6. Paste the key below.
class GooglePlacesConfig {
  static const String apiKey = 'AIzaSyB_-uOyQimLqBkDW_Vr8d88GX6Qk0lyksI';
}

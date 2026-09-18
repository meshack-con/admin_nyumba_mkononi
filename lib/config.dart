// baseUrl sasa inasomwa kutoka --dart-define=API_BASE_URL=... wakati wa
// `flutter run` au `flutter build web`. Ikiwa hujaitaja, itatumia
// http://127.0.0.1:8000 (backend ya local) kama default.
//
// Mfano wa production (Render): --dart-define=API_BASE_URL=https://nyumba-mkononi-backend.onrender.com
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

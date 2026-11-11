/// Dirección de la API. Se define al compilar:
/// flutter run --dart-define=API_URL=https://api.ejemplo.gov.co
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

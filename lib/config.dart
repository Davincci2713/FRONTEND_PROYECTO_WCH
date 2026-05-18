// Build-time: flutter build web --dart-define=API_BASE_URL=https://api.worldcuphub.online/api/v1
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.10.31:5001/api/v1',
);

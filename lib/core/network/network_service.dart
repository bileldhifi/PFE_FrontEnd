import 'api_client.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  late final ApiClient _apiClient;

  NetworkService._internal() {
    _apiClient = ApiClient();
  }

  factory NetworkService() {
    return _instance;
  }

  ApiClient get apiClient => _apiClient;
}

// Global instance for easy access
final networkService = NetworkService();

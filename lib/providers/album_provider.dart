import 'package:flutter/foundation.dart';
import '../services/album_service.dart';
import '../services/auth/auth.dart';

class AlbumProvider extends ChangeNotifier {
  final AlbumService _albumService = AlbumService();
  
  Map<String, dynamic>? _albumData;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get albumData => _albumData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get _currentUserId => AuthService().currentUserId ?? 1;

  Future<void> fetchAlbum() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _albumData = await _albumService.getUserAlbum(_currentUserId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> openPack() async {
    try {
      final result = await _albumService.openPack(_currentUserId);
      // Tras abrir un sobre, los datos del álbum cambian (nuevas cartas, repetidas, progreso)
      // Refrescamos silenciosamente el álbum en background.
      _refreshAlbumSilently();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshAlbumSilently() async {
    try {
      _albumData = await _albumService.getUserAlbum(_currentUserId);
      notifyListeners();
    } catch (_) {
      // Ignorar errores en refresh silencioso
    }
  }
}

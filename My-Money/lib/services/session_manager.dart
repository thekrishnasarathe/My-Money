import 'package:flutter/foundation.dart';

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const String defaultUserId = 'default_user';
  String _activeUserId = defaultUserId;
  String? _userEmail;
  bool _isAuthenticated = false;

  String get activeUserId => _activeUserId;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _activeUserId == defaultUserId;

  void setActiveUser({required String userId, String? email}) {
    _activeUserId = userId.isEmpty ? defaultUserId : userId;
    _userEmail = email;
    _isAuthenticated = _activeUserId != defaultUserId;
    notifyListeners();
  }

  void logoutToGuest() {
    _activeUserId = defaultUserId;
    _userEmail = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

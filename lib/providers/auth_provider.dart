import 'package:flutter/foundation.dart';
import 'package:warehouse/models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String get username => _user?.username ?? '';
  bool get isAdmin => _user?.isAdmin ?? false;

  void login(User u) {
    _user = u;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}

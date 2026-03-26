import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  UserProfile? _profile;
  bool _isLoading = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get canAnalyze => _profile?.canAnalyze ?? false;
  int get remainingCredits => _profile?.freeAnalysesRemaining ?? 0;
  bool get needsPhoneVerify => _profile?.phone == null;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    _profile = await _authService.getProfile();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithKakao() async {
    return await _authService.signInWithKakao();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<bool> verifyPhone(String phone) async {
    final isEarlybird = await _authService.verifyPhone(phone);
    await loadProfile(); // 프로필 갱신
    return isEarlybird;
  }

  Future<bool> useCredit() async {
    final success = await _authService.useAnalysisCredit();
    if (success) await loadProfile();
    return success;
  }
}

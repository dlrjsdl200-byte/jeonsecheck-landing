import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // 현재 유저
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // 카카오 로그인
  Future<bool> signInWithKakao() async {
    final res = await _supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'com.contractcheck.app://callback',
    );
    return res;
  }

  // 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 프로필 조회
  Future<UserProfile?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return UserProfile.fromJson(data);
  }

  // 전화번호 저장 + 얼리버드 매칭
  Future<bool> verifyPhone(String phone) async {
    final user = currentUser;
    if (user == null) return false;

    // 전화번호 저장
    await _supabase
        .from('profiles')
        .update({'phone': phone, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', user.id);

    // 얼리버드 매칭 확인
    final earlybird = await _supabase
        .from('earlybirds')
        .select()
        .eq('phone', phone)
        .eq('is_matched', false)
        .maybeSingle();

    if (earlybird != null) {
      // 매칭 성공: 분석권 1회 부여
      await _supabase.from('profiles').update({
        'is_earlybird': true,
        'free_analyses_remaining': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // 얼리버드 매칭 완료 표시
      await _supabase
          .from('earlybirds')
          .update({'is_matched': true})
          .eq('id', earlybird['id']);

      return true; // 얼리버드 매칭됨
    }

    return false; // 일반 가입
  }

  // 분석권 차감
  Future<bool> useAnalysisCredit() async {
    final profile = await getProfile();
    if (profile == null || !profile.canAnalyze) return false;

    await _supabase.from('profiles').update({
      'free_analyses_remaining': profile.freeAnalysesRemaining - 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profile.id);

    return true;
  }

  // 인증 상태 스트림
  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
}

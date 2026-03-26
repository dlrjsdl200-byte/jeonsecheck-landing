# Supabase Flutter 스킬

## 초기화
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
```

## 인증 (Auth)
```dart
// 카카오 OAuth 로그인 (PRD: 전화번호 기반 매칭)
await supabase.auth.signInWithOAuth(OAuthProvider.kakao);

// 전화번호 인증
await supabase.auth.signInWithOtp(phone: '+821012345678');

// 인증 상태 리스닝
supabase.auth.onAuthStateChange.listen((data) {
  final event = data.event;
  final session = data.session;
});

// 로그아웃
await supabase.auth.signOut();
```

## 데이터베이스 CRUD
```dart
// INSERT — 분석 결과 저장
await supabase.from('analyses').insert({
  'user_id': supabase.auth.currentUser!.id,
  'score': 85,
  'result_json': jsonEncode(result),
}).select();

// SELECT — 사용자 분석 이력 조회
final data = await supabase
  .from('analyses')
  .select()
  .eq('user_id', userId)
  .order('created_at', ascending: false);

// UPDATE
await supabase.from('analyses').update({'score': 90}).eq('id', id);

// DELETE
await supabase.from('analyses').delete().eq('id', id);

// RPC (서버 함수 호출)
final result = await supabase.rpc('match_earlybird', params: {'phone': phone});
```

## 스토리지 (파일 업로드/삭제)
```dart
// 업로드 (계약서 이미지/PDF)
final path = await supabase.storage
  .from('uploads')
  .upload('user_123/contract.pdf', file);

// 다운로드
final bytes = await supabase.storage
  .from('uploads')
  .download('user_123/contract.pdf');

// 삭제 (PRD: 원본 즉시 삭제)
await supabase.storage
  .from('uploads')
  .remove(['user_123/contract.pdf']);
```

## Row Level Security (RLS) 정책
```sql
-- 사용자 본인 데이터만 접근
ALTER TABLE analyses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own analyses"
ON analyses FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users insert own analyses"
ON analyses FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

## 주요 테이블 설계 (PRD 기반)
```sql
-- 사용자
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  phone TEXT UNIQUE,
  name TEXT,
  is_earlybird BOOLEAN DEFAULT false,
  free_analyses_remaining INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 분석 결과
CREATE TABLE analyses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  score INT,
  risk_level TEXT,
  result_json JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 결제
CREATE TABLE payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  amount INT,
  payment_key TEXT,
  status TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

## 보안 주의사항
- 환경변수(`SUPABASE_URL`, `SUPABASE_ANON_KEY`)는 `.env`에 저장, 커밋 금지
- RLS 반드시 활성화
- 업로드 원본은 분석 후 즉시 삭제 (PRD 요구사항)
- 개인정보 자동 마스킹 적용

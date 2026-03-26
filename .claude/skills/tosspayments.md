# 토스페이먼츠 결제 스킬

## 패키지
```yaml
dependencies:
  tosspayments_widget_sdk_flutter: ^latest
```

## Flutter 결제 위젯 연동 흐름

### 1. 결제 위젯 초기화
```dart
import 'package:tosspayments_widget_sdk_flutter/tosspayments_widget_sdk_flutter.dart';

// 클라이언트 키 (테스트/라이브)
const clientKey = 'test_ck_...';  // 토스페이먼츠 대시보드에서 확인
```

### 2. 결제 요청 플로우
```
사용자 → 결제 버튼 → 토스 결제위젯 → 결제 승인 → 서버 검증 → 완료
```

#### 클라이언트 (Flutter)
```dart
// 결제 위젯 화면으로 이동
PaymentWidget(
  clientKey: clientKey,
  customerKey: 'user_unique_id',
  amount: 9900,           // PRD: 얼리버드 9,900원
  orderId: 'order_${uuid}',
  orderName: '계약체크 1회 분석권',
  successUrl: 'https://your-domain.com/payment/success',
  failUrl: 'https://your-domain.com/payment/fail',
);
```

#### 서버 (Supabase Edge Function)
```typescript
// 결제 승인 API 호출
const response = await fetch('https://api.tosspayments.com/v1/payments/confirm', {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${btoa(secretKey + ':')}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    paymentKey,
    orderId,
    amount,
  }),
});
```

### 3. 결제 성공/실패 처리
```dart
// 성공 콜백
void onPaymentSuccess(String paymentKey, String orderId, int amount) async {
  // Supabase Edge Function으로 승인 요청
  await supabase.functions.invoke('confirm-payment', body: {
    'paymentKey': paymentKey,
    'orderId': orderId,
    'amount': amount,
  });
}

// 실패 콜백
void onPaymentFail(String code, String message) {
  showErrorDialog('결제 실패: $message');
}
```

## Android 설정
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
<application android:usesCleartextTraffic="true">
  <!-- 카드사 앱 URL scheme 처리 -->
</application>
```

## 가격 정책 (PRD)
| 상품 | 가격 | 비고 |
|------|------|------|
| 얼리버드 | 9,900원 | 사전판매, 1회 분석권 |
| 1회 분석 | 14,900원 | 정가 |
| 3회 패키지 | 29,900원 | 40% 할인 |

## 얼리버드 전화번호 매칭 플로우
1. 결제 시 전화번호+이름 수집 (구글폼+토스페이먼츠)
2. 결제 완료 → "얼리버드 예약 완료" 자동 문자
3. 출시 시 카카오 알림톡으로 오픈 안내
4. 앱 가입 시 전화번호 인증 → Supabase DB 매칭 → 1회 분석권 자동 적용

## 보안
- Secret Key는 서버(Edge Function)에서만 사용
- Client Key만 클라이언트에 노출
- 결제 금액 서버 검증 필수 (위변조 방지)

# 카카오 알림톡 스킬

## 용도 (PRD)
- 얼리버드 결제 완료 알림
- 서비스 출시 안내
- 분석 완료 알림

## 연동 방식
카카오 비즈메시지 API 또는 NHN Cloud / Solapi 등 중계 서비스 사용

### Solapi (권장 — 소규모 서비스 적합)
```typescript
// Supabase Edge Function
const response = await fetch('https://api.solapi.com/messages/v4/send', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${SOLAPI_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    message: {
      to: '01012345678',
      from: '발신번호',
      kakaoOptions: {
        pfId: '카카오채널_ID',
        templateId: 'TEMPLATE_001',
        variables: {
          '#{이름}': userName,
          '#{날짜}': date,
        },
      },
    },
  }),
});
```

## 알림톡 템플릿 (PRD 기반)

### 얼리버드 결제 완료
```
[계약체크] 얼리버드 예약 완료!

#{이름}님, 계약체크 얼리버드 결제가 완료되었습니다.

- 결제금액: 9,900원
- 혜택: 서비스 출시 시 1회 무료 분석권

출시 시 카카오 알림톡으로 안내드리겠습니다.
감사합니다!
```

### 서비스 출시 안내
```
[계약체크] 서비스가 출시되었습니다!

#{이름}님, 기다려주셔서 감사합니다.
계약체크가 드디어 출시되었습니다!

얼리버드 1회 무료 분석권이 준비되어 있습니다.
지금 바로 시작해보세요.

▶ 앱 다운로드: #{링크}
```

### 분석 완료 알림
```
[계약체크] 분석이 완료되었습니다!

#{이름}님의 전세 계약서 분석이 완료되었습니다.

- 안전 점수: #{점수}/100
- 위험 등급: #{등급}

자세한 결과는 앱에서 확인하세요.
▶ 결과 보기: #{링크}
```

## 주의사항
- 카카오 비즈니스 채널 등록 필수
- 알림톡 템플릿 사전 심사 필요 (1~2일)
- 발신번호 사전 등록 필수
- 야간 발송 제한 (21:00~08:00)

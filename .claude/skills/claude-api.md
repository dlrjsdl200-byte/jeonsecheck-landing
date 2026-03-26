# Claude API 스킬 (AI 분석 엔진)

## 모델 선택 (PRD 기반)
- **1차 선택**: Claude Haiku 4.5 (`claude-haiku-4-5`) — 건당 ~64원, $1/$5 per MTok
- **품질 부족 시**: Claude Sonnet 4.6 (`claude-sonnet-4-6`) — 건당 ~193원
- API 2회 호출: 1회차(OCR+분석) + 2회차(교차검증+리포트)

## Supabase Edge Function에서 호출 (Dart/TypeScript)
```typescript
// supabase/functions/analyze/index.ts
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY') });

const response = await client.messages.create({
  model: 'claude-haiku-4-5',
  max_tokens: 4096,
  system: ANALYSIS_SYSTEM_PROMPT,
  messages: [{ role: 'user', content: userContent }],
});
```

## Vision API — 문서 이미지 분석
```typescript
// 계약서/등기부등본 사진 분석
const message = await client.messages.create({
  model: 'claude-haiku-4-5',
  max_tokens: 4096,
  messages: [{
    role: 'user',
    content: [
      {
        type: 'image',
        source: {
          type: 'base64',
          media_type: 'image/jpeg',
          data: base64ImageData,
        },
      },
      {
        type: 'text',
        text: '이 전세 계약서를 분석해주세요. JSON 형식으로 응답하세요.',
      },
    ],
  }],
});
```

## PDF 문서 분석
```typescript
const message = await client.messages.create({
  model: 'claude-haiku-4-5',
  max_tokens: 4096,
  messages: [{
    role: 'user',
    content: [
      {
        type: 'document',
        source: {
          type: 'base64',
          media_type: 'application/pdf',
          data: base64PdfData,
        },
      },
      { type: 'text', text: ANALYSIS_PROMPT },
    ],
  }],
});
```

## 프롬프트 캐싱 (90% 비용 절약)
```typescript
// 시스템 프롬프트를 캐싱하여 반복 호출 비용 절감
const response = await client.messages.create({
  model: 'claude-haiku-4-5',
  max_tokens: 4096,
  system: [{
    type: 'text',
    text: LONG_SYSTEM_PROMPT,  // 분석 규칙, HUG 기준 등
    cache_control: { type: 'ephemeral' },  // 5분 TTL
  }],
  messages: [{ role: 'user', content: documentContent }],
});

// 캐시 사용량 확인
console.log(`Cache write: ${response.usage.cache_creation_input_tokens}`);
console.log(`Cache read: ${response.usage.cache_read_input_tokens}`);
```

### 캐싱 비용 구조
| 구분 | 비율 |
|------|------|
| 캐시 기록 (5분) | 기본 x1.25 |
| 캐시 읽기 | 기본 x0.1 |
| 최소 캐시 토큰 | Haiku: 4,096 / Sonnet: 2,048 |

## 스트리밍 (실시간 분석 피드백)
```typescript
const stream = await client.messages.stream({
  model: 'claude-haiku-4-5',
  max_tokens: 4096,
  messages: [{ role: 'user', content: prompt }],
});

for await (const event of stream) {
  if (event.type === 'content_block_delta') {
    // 실시간으로 클라이언트에 전달
    sendToClient(event.delta.text);
  }
}
```

## Tool Use — 구조화된 분석 결과
```typescript
const tools = [
  {
    name: 'contract_analysis',
    description: '계약서 분석 결과를 구조화된 형태로 반환',
    input_schema: {
      type: 'object',
      properties: {
        safety_score: { type: 'number', description: '안전 점수 0-100' },
        risk_level: { type: 'string', enum: ['safe', 'caution', 'danger'] },
        standard_contract: { type: 'boolean', description: '표준계약서 여부' },
        issues: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              category: { type: 'string' },
              severity: { type: 'string', enum: ['info', 'warning', 'critical'] },
              description: { type: 'string' },
              recommendation: { type: 'string' },
            },
          },
        },
        negotiation_tips: { type: 'array', items: { type: 'string' } },
        recommended_clauses: { type: 'array', items: { type: 'string' } },
      },
      required: ['safety_score', 'risk_level', 'issues'],
    },
  },
];
```

## 분석 항목 (PRD 기반 시스템 프롬프트 핵심)
1. **계약서**: 표준계약서 판별 (6개 항목 중 4개+), 특약사항, 계약기간, 보증금, 갱신요구권
2. **등기부등본**: 갑구(소유권), 을구(근저당), 깡통전세 위험도 (HUG 기준: 공시가격x140%x90%=126%)
3. **건축물대장**: 용도, 위반건축물, 무허가, 면적 일치
4. **교차검증**: 소유자 3중 대조, 주소 3중 대조, 면적/용도 적합성
5. **AI 생성**: 종합 안전 점수, 쉬운 말 해설, 협상 멘트, 추천 특약, 체크리스트

## 보안
- API 키는 서버 사이드(Edge Function)에서만 사용
- 클라이언트에 절대 노출 금지
- 개인정보 마스킹 후 저장

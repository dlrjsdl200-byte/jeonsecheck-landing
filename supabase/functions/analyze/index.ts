import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// 1회차 시스템 프롬프트
const SYSTEM_PROMPT_PASS1 = `당신은 전세/월세 계약 서류 항목을 자동으로 확인해주는 기술적 도구입니다.
사용자가 업로드한 서류(계약서, 등기부등본, 건축물대장)의 내용을 읽고, 주요 항목을 기계적으로 대조·확인하여 정보를 정리합니다.
당신은 계약을 평가하거나 법적 분석을 하는 것이 아닙니다.

## 역할과 한계 (필수 준수)
- 당신은 법률 자문을 제공하지 않습니다. 서류 항목 자동 확인 + 공식 기준 참고 정보 제공만 합니다.
- 당신은 계약의 안전 여부, 적합 여부를 평가하지 않습니다.
- 절대 법적 판단, 계약 체결/해지 권유, 법적 조언을 하지 마세요.
- "~하세요", "~하지 마세요" 같은 지시형 표현을 사용하지 마세요.
- "위험합니다", "불가합니다", "무효입니다" 같은 단정형 표현을 사용하지 마세요.
- "임대인이 사기를 치고 있습니다" 같은 상대방에 대한 판단을 하지 마세요.
- 항상 "~일 수 있습니다", "~확인이 필요합니다", "~전문가 상담을 권장합니다"로 표현하세요.
- 공식 기준(HUG, 주임법 등)을 인용할 때는 반드시 출처를 명시하세요.
- 특약 문구를 제안할 때는 "일반적으로 사용되는 예시"임을 반드시 밝히고, "실제 계약 반영 시 전문가와 상의하세요"를 함께 안내하세요.
- 특약 예시를 제공하는 것은 괜찮지만, "이 특약을 넣으면 ~할 수 있습니다" 같은 법적 효과 설명은 하지 마세요.

## 등급 표현 (반드시 이 용어만 사용)
- "양호" (안전/문제없음 대신)
- "주의 권장" (주의/경고 대신)
- "확인 필요" (위험/불가 대신)
- "참고" (단순 정보 전달)

## 확인 항목

### 계약서
A. 표준계약서 판별 — 법무부 표준계약서 필수 항목 6개 포함 여부:
1. 임대할 부분의 표시 (소재지, 면적, 구조)
2. 계약 내용 (보증금, 차임, 임대차 기간)
3. 계약 조건 (인도일, 잔금 지급일)
4. 계약 당사자 정보 (임대인/임차인 인적사항)
5. 중개업소 정보 (상호, 대표, 등록번호)
6. 특약사항란 존재 여부
- 4개+ → "표준계약서 항목에 부합합니다" / 3개 이하 → "표준계약서 항목이 일부 누락되어 있습니다"

B. 특약 7개 포함 여부 (미포함 시 일반적 예시 문구 안내, 실제 반영 시 전문가 상의 안내):
1. 권리관계 유지
2. 보증금 반환 시기/방법
3. 보증보험 가입 협조
4. 계약 후 새로운 권리 변동 시 해지 (기존 근저당과 구분 — 이 특약은 계약 체결 이후 새로 발생하는 권리 변동에 대한 것)
5. 대출 불가 시 무효
6. 수리비 책임
7. 원상복구 범위

C. 기타: 계약기간 2년 미만 여부, 보증금/지급방식, 갱신요구권, 차임증액 5% 제한, 필수 기재사항

### 등기부등본
A. 갑구: 소유자, 소유권 이전 이력, 압류/가압류/경매 개시결정/처분금지 가처분 (1건이라도 있으면 "확인 필요"), 신탁등기 (있으면 "확인 필요"), 법인 소유 여부
B. 을구: 근저당 합계 (채권최고액은 통상 실제 대출금의 120~130%, 출처: 금융감독원), 전세권, 깡통전세 HUG 기준 비율

깡통전세 계산: (선순위 채권 합계 + 보증금) ÷ 주택가격 × 100%
- ~70%: 양호 / 70~80%: 주의 권장 / 80~90%: 확인 필요 / 90%+: 보증보험 가입이 어려울 수 있는 구간
- 아파트: KB시세 기준 / 비아파트: 공시가격×140% 추정
- 출처: HUG 전세보증금반환보증 업무처리기준 (2023.05~)

### 건축물대장
- 건물 용도 확인 (주택: 단독/다가구/다세대/연립/아파트)
- 비주택 용도 참고: 근린생활시설, 업무시설(오피스텔), 판매시설, 숙박시설 등 (건축법 시행령 별표 1)
- 위반건축물, 무허가 여부
- 주소(지번/도로명)와 면적 추출

### 부동산 용어 쉬운 설명
용어가 처음 등장할 때 "(쉬운 설명: ~)" 형태로 함께 안내:
- 갑구: 소유권 기록 부분 / 을구: 소유권 이외 권리 기록 부분
- 근저당: 대출 담보로 설정하는 권리, 미상환 시 경매 가능
- 가압류: 채무 분쟁으로 법원이 처분을 임시 금지하는 것
- 가처분/처분금지: 법원이 매각·담보 제공을 금지하는 것
- 신탁등기: 신탁회사에 관리를 맡긴 것, 동의 없는 계약은 효력에 영향
- 확정일자: 계약서에 날짜 도장을 받는 것, 보증금 우선변제권 확보에 도움

## 출력: 반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트 없이 JSON만 출력하세요.

{
  "documents_found": ["contract"|"registry"|"building"],
  "contract_analysis": {
    "standard_contract": { "included_count": N, "total": 6, "verdict": "...", "missing_items": [] },
    "special_clauses": [{ "name": "...", "found": bool, "recommended_text": "..." | null }],
    "other_checks": [{ "item": "...", "value": "...", "status": "양호|주의 권장|확인 필요|참고", "note": "..." }]
  },
  "registry_analysis": {
    "owner": "...", "mortgages_total": N, "mortgages_detail": [{ "creditor": "...", "amount": N, "date": "..." }],
    "seizures": [{ "type": "...", "creditor": "...", "amount": N, "date": "..." }],
    "trust": bool, "corporation": bool, "ownership_transfers": N,
    "gap_ratio": { "value": N, "calculation": "...", "estimated_price": N, "grade": "...", "note": "..." }
  },
  "building_analysis": {
    "usage": "...", "is_residential": bool, "violation": bool, "unauthorized": bool, "address": "...", "area": N, "owner": "..."
  },
  "extracted_data": {
    "contract_owner": "...", "contract_address": "...", "contract_area": N, "contract_deposit": N,
    "registry_owner": "...", "registry_address": "...",
    "building_owner": "...", "building_address": "...", "building_area": N
  }
}`;

// 2회차 시스템 프롬프트
const SYSTEM_PROMPT_PASS2 = `당신은 전세/월세 계약 서류 항목을 자동으로 확인해주는 기술적 도구입니다.
1회차 확인 결과를 바탕으로 서류 간 항목을 교차 대조하고, 확인 결과 리포트를 생성합니다.
당신은 계약을 평가하거나 법적 분석을 하는 것이 아닙니다.

## 역할과 한계 (필수 준수)
- 법률 자문 제공 안 함. 서류 항목 자동 확인 + 공식 기준 참고 정보 제공만.
- 계약의 안전 여부, 적합 여부를 평가하지 않음.
- 지시형("~하세요"), 단정형("위험합니다") 표현 금지.
- "~일 수 있습니다", "~확인이 필요합니다", "~전문가 상담을 권장합니다"로 표현.
- 공식 기준 인용 시 출처 명시. 특약 예시는 "일반적 예시"임을 밝히고 전문가 상의 안내.

## 점수(score) 규칙
- "체크 항목 충족률"이다. "계약 안전 점수"가 아니다.
- 종합 평가 금지.

## 요약(summary) 규칙
- "확인한 항목 요약입니다"로 시작. 사실 나열만. "이 계약은 ~" 평가 금지.
- 마지막에 "최종 판단은 반드시 전문가와 상의하시기 바랍니다" 포함.

## 참고 대화 예시(talk_examples) 규칙
- "~할 수 있을까요?" 질문 형태만. 지시/판단 금지.
- 임대인/중개사에게 정중한 확인 요청 톤.

## 교차 검증 항목
1. 소유자 3중 대조 (계약서 vs 등기부 vs 건축물대장)
2. 주소 3중 대조 (동 단위, 지번/도로명 혼용 시 표기 방식 차이 안내)
3. 면적 대조 (5%+ 차이 시 안내)
4. 용도 적합성
5. 신탁 + 계약당사자 대조
6. 깡통전세 종합 참고 수치 확인

## 점수 산정 (기계적 합산, 주관적 가중 금지)
| 항목 | 배점 | 감점 |
|------|------|------|
| 표준계약서 부합 | 8점 | 1개 미포함당 -2점 |
| 특약 포함 | 14점 (2점×7) | 1개 미포함당 -2점 |
| 소유자 일치 | 10점 | 불일치 시 -10점 |
| 주소 일치 | 8점 | 불일치 시 -8점 |
| 면적 일치 | 5점 | 5%+ 차이 시 -5점 |
| 깡통전세 비율 | 15점 | 70~80%:-4, 80~90%:-10, 90%+:-15 |
| 압류/가압류/경매/처분금지 없음 | 25점 | 1건이라도 있으면 -25점 |
| 신탁 없음 | 10점 | 있으면 -10점 |
| 건물 용도 적합 | 5점 | 부적합 시 -5점 |
총 100점. 80~100: 양호 / 60~79: 주의 권장 / 0~59: 확인 필요
서류 없는 항목은 배점 제외 후 비율 환산.

## 출력: 반드시 아래 JSON만 출력. 다른 텍스트 없이.

{
  "score": N,
  "score_label": "체크 항목 충족률",
  "grade": "양호|주의 권장|확인 필요",
  "grade_description": "...",
  "items": [{ "category": "...", "status": "양호|주의 권장|확인 필요|참고", "title": "...", "description": "...", "recommendation": "..."|null }],
  "summary_notice": "아래는 각 체크 항목의 확인 결과를 요약한 것이며, 계약 자체에 대한 평가가 아닙니다.",
  "summary": "확인한 항목 요약입니다. ...",
  "talk_examples": ["..."],
  "recommended_clauses_notice": "아래는 일반적으로 사용되는 특약 예시입니다. 실제 계약에 반영 시 전문가(변호사/법무사)와 상의하세요.",
  "recommended_clauses": ["..."],
  "checklist": ["..."],
  "disclaimer": "본 결과는 서류 항목을 자동으로 확인한 참고 정보이며, 법률 자문이나 계약 평가가 아닙니다. 이 도구는 계약의 안전 여부를 판단하지 않습니다. 실제 계약 전 반드시 전문가(변호사, 법무사, 공인중개사)와 상담하시기 바랍니다."
}`;

async function callClaude(
  systemPrompt: string,
  userContent: Array<Record<string, unknown>>,
  maxTokens = 4096
): Promise<Record<string, unknown>> {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5-20251001",
      max_tokens: maxTokens,
      system: [
        {
          type: "text",
          text: systemPrompt,
          cache_control: { type: "ephemeral" },
        },
      ],
      messages: [{ role: "user", content: userContent }],
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Claude API error: ${response.status} ${error}`);
  }

  const data = await response.json();
  const text = data.content[0].text;

  // JSON 추출 (```json ... ``` 감싸기 대응)
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error("Claude did not return valid JSON");

  return JSON.parse(jsonMatch[0]);
}

function maskPersonalInfo(
  result: Record<string, unknown>
): Record<string, unknown> {
  const json = JSON.stringify(result);

  // 이름 마스킹: 2~4글자 한글 이름 → 첫글자 + ○
  const masked = json.replace(
    /([가-힣])([가-힣]{1,3})/g,
    (match, first) => {
      // 일반적인 단어는 건드리지 않도록 길이 체크
      if (match.length > 4) return match;
      return first + "○".repeat(match.length - 1);
    }
  );

  return JSON.parse(masked);
}

Deno.serve(async (req) => {
  try {
    // CORS
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers":
            "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Auth 확인
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { paths, doc_types } = await req.json();

    if (!paths || !doc_types || paths.length === 0) {
      return new Response(
        JSON.stringify({ error: "No documents provided" }),
        { status: 400 }
      );
    }

    // 1. 업로드된 파일들을 base64로 변환
    const userContent: Array<Record<string, unknown>> = [];

    for (let i = 0; i < paths.length; i++) {
      const { data: fileData, error: fileError } = await supabase.storage
        .from("documents")
        .download(paths[i]);

      if (fileError) throw new Error(`File download error: ${fileError.message}`);

      const buffer = await fileData.arrayBuffer();
      const base64 = btoa(
        String.fromCharCode(...new Uint8Array(buffer))
      );

      const isPdf = paths[i].toLowerCase().endsWith(".pdf");
      const mediaType = isPdf ? "application/pdf" : "image/jpeg";

      if (isPdf) {
        userContent.push({
          type: "document",
          source: { type: "base64", media_type: mediaType, data: base64 },
        });
      } else {
        userContent.push({
          type: "image",
          source: { type: "base64", media_type: mediaType, data: base64 },
        });
      }

      const docLabel =
        doc_types[i] === "contract"
          ? "계약서"
          : doc_types[i] === "registry"
          ? "등기부등본"
          : "건축물대장";

      userContent.push({
        type: "text",
        text: `위 이미지는 ${docLabel}입니다.`,
      });
    }

    userContent.push({
      type: "text",
      text: "위 서류들의 주요 항목을 확인하고, 지정된 JSON 형식으로 결과를 출력해주세요.",
    });

    // 2. 1회차 호출 (OCR + 개별 확인)
    const pass1Result = await callClaude(SYSTEM_PROMPT_PASS1, userContent);

    // 3. 2회차 호출 (교차검증 + 리포트)
    const pass2Content = [
      {
        type: "text",
        text: `1회차 서류 확인 결과입니다. 이를 바탕으로 교차 검증을 수행하고 최종 리포트를 JSON으로 생성해주세요.\n\n${JSON.stringify(pass1Result, null, 2)}`,
      },
    ];

    const pass2Result = await callClaude(
      SYSTEM_PROMPT_PASS2,
      pass2Content,
      8192
    );

    // 4. 개인정보 마스킹
    const maskedResult = maskPersonalInfo(pass2Result);

    return new Response(JSON.stringify(maskedResult), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Analysis error:", error);
    return new Response(
      JSON.stringify({
        error: "서류 확인 중 오류가 발생했습니다.",
        detail: error.message,
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});

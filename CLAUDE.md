# TokenGauge

macOS 메뉴바 앱 — AI 서비스(Claude, ChatGPT, Gemini) 토큰 사용량 실시간 모니터링.

## 기술 스택

- **언어**: Swift 6 (strict concurrency, default MainActor isolation)
- **UI**: SwiftUI
- **타겟**: macOS 14+ (현재 Xcode 설정: macOS 26.2)
- **Bundle ID**: com.tokengauge.TokenGauge
- **아키텍처**: Provider 패턴 (AIProvider 프로토콜 → Claude/ChatGPT/Gemini 확장)

## 프로젝트 구조

```
TokenGauge/
├── App/                    # @main, AppDelegate(NSStatusItem+NSPopover), Constants
├── Core/
│   ├── Protocols/          # AIProvider 프로토콜
│   ├── Models/             # UsageData, UsageLimit, AuthType, ProviderStatus
│   └── Registry/           # ProviderRegistry (프로바이더 관리)
├── Providers/
│   └── Claude/             # ClaudeProvider, ClaudeAPI, ClaudeParser, ClaudeAuthService
├── Infrastructure/
│   ├── Keychain/           # KeychainHelper (Security.framework)
│   ├── Network/            # APIClient (URLSession)
│   └── Scheduler/          # RefreshScheduler (스마트 폴링)
├── Views/
│   ├── Popover/            # PopoverView, UsageCardView, ProgressBarView
│   ├── Components/         # TimeFormatter 등 공통 컴포넌트
│   └── Settings/           # SettingsView
└── Assets.xcassets/
```

## 빌드

```bash
xcodebuild -project TokenGauge.xcodeproj -scheme TokenGauge -configuration Debug build
```

## 핵심 API

- **엔드포인트**: `https://api.anthropic.com/api/oauth/usage`
- **인증**: `Authorization: Bearer {accessToken}`
- **필수 헤더**: `anthropic-beta: oauth-2025-04-20`, `anthropic-version: 2023-06-01`
- **권장 헤더**: `User-Agent: TokenGauge/1.0`, `Accept: */*`
- **Keychain 서비스**: `Claude Code-credentials`
- **토큰 구조**: `{"claudeAiOauth": {"accessToken": "...", "refreshToken": "...", "expiresAt": "..."}}`
- **응답 필드**: `five_hour`, `seven_day`, `seven_day_sonnet`, `seven_day_opus`, `extra_usage`
- **각 필드**: `{"utilization": 29.0, "resets_at": "2025-03-06T18:00:00Z"}`
- **extra_usage 확장**: `{"is_enabled": true, "utilization": 0, "used_credits": 0, "monthly_limit": 5000}` (센트 단위)

## 스마트 폴링 전략 (ADR-005)

- AI 앱 실행 중 → 10분마다 (활성 모드)
- AI 앱 미실행 → 1시간마다 (절전 모드)
- 앱 켜짐(NSWorkspace didLaunch) → 즉시 요청 + 활성 모드
- 429 수신 → 파일 캐시 사용 + exponential backoff (10분→20분→40분→최대 30분)
- 감시 대상:
  - GUI 앱: `com.anthropic.claudefordesktop` (NSWorkspace)
  - CLI 프로세스: `claude` (pgrep)

## 캐시 전략 (cc-alchemy 참고)

- 파일 캐시: `~/.claude/tokengauge_cache.json` (마지막 성공 데이터)
- 캐시 TTL: 5분 (TTL 내에는 API 호출 생략)
- 토큰 핑거프린트: 토큰 마지막 8자리로 계정 변경 감지 → 캐시 무효화
- Backoff 파일: `~/.claude/tokengauge_backoff.json` (재시도 대기 시간)

## UI

- **메뉴바**: `5h:[26%] | 7d:[15%]` — 퍼센티지에 severity 색상 적용 (NSAttributedString)
- **색상 3단계**: 초록(0~59%) → 주황(60~79%) → 빨강(80%~)
- **팝오버 헤더**: 갱신 시간 + 폴링 모드(활성/절전) + stale 시 "캐시" 뱃지
- **사용량 카드**: 메인 한도 / 모델별 한도 섹션 분리, 추가 사용량 달러 표시
- **팝오버 푸터**: 갱신 주기 + 버전
- **설정**: Launch at Login (SMAppService), 버전/빌드 정보

## 개발 Phase

- **Phase 0** (완료): Python SwiftBar 프로토타입
- **Phase 1** (완료): macOS 네이티브 앱 — Claude 프로바이더 + 스마트 폴링 + UI
- **Phase 2**: claude.ai 웹 추적 (세션 쿠키)
- **Phase 3**: 멀티 프로바이더 (ChatGPT, Gemini)
- **Phase 4**: 배포 (Homebrew, Sparkle, 공증)

## 컨벤션

- 한국어 우선 (UI, 주석)
- Provider 추가 시 반드시 AIProvider 프로토콜 구현
- Keychain 접근은 KeychainHelper를 통해서만
- 429 에러 시 반드시 캐시 fallback + backoff 적용

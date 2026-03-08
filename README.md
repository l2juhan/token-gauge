# TokenGauge

macOS 메뉴바에서 AI 서비스 토큰 사용량을 실시간으로 확인하는 네이티브 앱.

Claude Code의 OAuth 토큰을 Keychain에서 자동으로 읽어오기 때문에 별도 설정이 필요 없음.

## 기능

- **메뉴바 표시** — `5h:29% 7d:10%` 형태로 항상 보임
- **팝오버 UI** — 클릭 시 상세 사용량 카드 (5시간/7일/모델별 한도, 리셋 시간)
- **색상 코딩** — 초록(~59%) → 주황(60~79%) → 빨강(80%~)
- **3단계 캐시 fallback** — API rate limit(429) 시 메모리 → 파일 캐시 → cc-alchemy 캐시 순으로 표시
- **Provider 패턴** — Claude, ChatGPT, Gemini 등 멀티 프로바이더 확장 가능

## 스크린샷

<img width="320" alt="메뉴바" src="https://github.com/user-attachments/assets/placeholder-menubar.png">

> 스크린샷은 추후 추가 예정

## 사전 준비

- macOS 14+ (Sonoma)
- Xcode 16+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 설치 + 로그인

```bash
npm install -g @anthropic-ai/claude-code
claude  # 로그인
```

## 빌드 & 실행

```bash
# Xcode에서 열기
open TokenGauge.xcodeproj

# 또는 커맨드라인 빌드
xcodebuild -project TokenGauge.xcodeproj -scheme TokenGauge -configuration Debug build
```

Xcode에서 `Cmd+R`로 실행하면 메뉴바에 `5h:--% 7d:--%`가 나타남.

## 동작 원리

```
Keychain에서 OAuth 토큰 읽기
  → api.anthropic.com/api/oauth/usage 호출
  → 성공: 메뉴바 + 팝오버 렌더링, 파일 캐시 저장
  → 429:  캐시에서 마지막 데이터 표시 (stale)
  → 401/403: 토큰 만료 안내
```

- **인증**: Claude Code가 Keychain에 저장한 OAuth 토큰 사용 (`Claude Code-credentials`)
- **자체 캐시**: `~/.claude/tokengauge_cache.json`
- **cc-alchemy fallback**: `~/.claude/statusline_cache.json` (읽기 전용)

## 프로젝트 구조

```
TokenGauge/
├── App/                    # @main, AppDelegate, Constants
├── Core/
│   ├── Protocols/          # AIProvider 프로토콜
│   ├── Models/             # UsageData, UsageLimit, AuthType, ProviderStatus
│   └── Registry/           # ProviderRegistry
├── Providers/
│   └── Claude/             # ClaudeProvider, API, Parser, AuthService, Models
├── Infrastructure/
│   ├── Cache/              # UsageCacheService (파일 캐시)
│   ├── Keychain/           # KeychainHelper (Security.framework)
│   ├── Network/            # APIClient
│   └── Scheduler/          # RefreshScheduler
└── Views/
    ├── Popover/            # PopoverView, UsageCardView, ProgressBarView
    ├── Components/         # TimeFormatter, ClaudeIconView
    └── Settings/           # SettingsView
```

## 기술 스택

- **Swift 6** (strict concurrency)
- **SwiftUI** + AppKit (NSStatusItem + NSPopover)
- **macOS 14+**

## 로드맵

- [x] Phase 0: Python SwiftBar 프로토타입
- [x] Phase 1: macOS 네이티브 앱 (Claude)
- [ ] Phase 2: claude.ai 웹 추적
- [ ] Phase 3: 멀티 프로바이더 (ChatGPT, Gemini)
- [ ] Phase 4: 배포 (Homebrew, Sparkle, 공증)

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| `5h:-- 7d:--` | Claude Code 미설치 또는 미로그인 | 터미널에서 `claude` 실행 후 로그인 |
| 토큰 만료 오류 | OAuth 토큰 만료 | `claude` 재실행으로 토큰 갱신 |
| 429 rate limit | API 요청 제한 | 캐시 데이터 자동 표시, 잠시 대기 |
| 메뉴바 안 보임 | 노치/카메라에 가려짐 | 다른 메뉴바 아이콘 정리 후 확인 |

## 라이선스

MIT

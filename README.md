# TokenGauge

macOS 메뉴바에서 Claude 사용량을 실시간으로 확인하는 [SwiftBar](https://github.com/swiftbar/SwiftBar) 플러그인.

Claude Code의 OAuth 토큰을 Keychain에서 자동으로 읽어오기 때문에 별도 설정이 필요 없음.

## 기능

- **메뉴바 표시** — `5h:29% ǀ 7d:10%` 형태로 항상 보임
- **색상 코딩** — 초록(~59%) → 주황(60~79%) → 빨강(80%~)
- **드롭다운 상세** — 5시간/7일 윈도우, 모델별(Sonnet/Opus) 한도, 리셋 시간
- **429 캐시 fallback** — API rate limit 시 마지막 성공 데이터를 표시
- **5분 자동 새로고침**

## 사전 준비

- macOS 14+ (Sonoma)
- [SwiftBar](https://github.com/swiftbar/SwiftBar) 설치
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 설치 + 로그인

```bash
brew install --cask swiftbar
npm install -g @anthropic-ai/claude-code
claude  # 로그인
```

## 설치

```bash
# SwiftBar 플러그인 폴더에 복사 (폴더 경로는 SwiftBar 설정에서 확인)
cp token-gauge.5m.py ~/SwiftBarPlugins/
chmod +x ~/SwiftBarPlugins/token-gauge.5m.py
```

SwiftBar가 자동으로 인식하고 5분마다 실행함.

## 동작 원리

```
Keychain에서 OAuth 토큰 읽기
  → api.anthropic.com/api/oauth/usage 호출
  → 성공: 메뉴바 + 드롭다운 렌더링, 캐시 저장
  → 429:  캐시에서 마지막 데이터 표시 + 경고
  → 401/403: 토큰 만료 안내
```

- 인증: Claude Code가 Keychain에 저장한 OAuth 토큰 사용 (`Claude Code-credentials`)
- 캐시: `~/.cache/token-gauge-last.json`에 마지막 성공 응답 저장

## 커스터마이징

`token-gauge.5m.py` 파일 상단의 상수를 수정:

| 상수 | 기본값 | 설명 |
|------|--------|------|
| `THRESHOLD_WARNING` | 60 | 주황색 전환 기준 (%) |
| `THRESHOLD_CRITICAL` | 80 | 빨간색 전환 기준 (%) |

새로고침 주기를 바꾸려면 파일명의 `5m` 부분을 수정 (예: `10m` = 10분, `30s` = 30초).

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| `TG: ⚙️` | Claude Code 미설치 또는 미로그인 | 터미널에서 `claude` 실행 후 로그인 |
| `TG: 🔑` | OAuth 토큰 만료 | `claude` 재실행으로 토큰 갱신 |
| `오류: http_429` | API rate limit | 자동 복구 대기 or 새로고침 주기 늘리기 |
| `⚠️ 캐시 데이터` | 429 상태에서 캐시로 표시 중 | 정상 — 다음 성공 시 자동 갱신 |

## 라이선스

MIT
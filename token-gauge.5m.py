#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TokenGauge — SwiftBar 플러그인 (OAuth 버전)
Claude Code Keychain의 OAuth 토큰으로 사용량 조회

설치 방법:
1. brew install --cask swiftbar
2. Claude Code 설치 + 로그인 (npm install -g @anthropic-ai/claude-code && claude)
3. 이 파일을 SwiftBar 플러그인 폴더에 복사
4. chmod +x token-gauge.5m.py

파일명의 5m = 5분마다 자동 새로고침
쿠키 방식과 달리 설정할 것 없음 — Keychain에서 자동으로 토큰 읽음
"""

import json
import urllib.request
import urllib.error
import ssl
import subprocess
from datetime import datetime, timezone
import os

# ═══════════════════════════════════════════════════
# 상수 (React의 constants.ts에 해당)
# ═══════════════════════════════════════════════════

# Claude Code가 Keychain에 저장하는 서비스 이름
KEYCHAIN_SERVICE = "Claude Code-credentials"

# OAuth 전용 사용량 API (Cloudflare 안 거침!)
# 세션 쿠키 방식: claude.ai/api/organizations/{org_id}/usage
# OAuth 방식:     api.anthropic.com/api/oauth/usage  ← 이거 사용
API_URL = "https://api.anthropic.com/api/oauth/usage"

# 캐시 파일 경로 (429 대비 마지막 성공 데이터 저장)
# React로 치면 localStorage에 해당
CACHE_FILE = os.path.expanduser("~/.cache/token-gauge-last.json")

# 색상 임계값
THRESHOLD_WARNING = 60
THRESHOLD_CRITICAL = 80

# ═══════════════════════════════════════════════════
# 색상 정의
# ═══════════════════════════════════════════════════

COLORS = {
    "normal": "#4ADE80",     # 초록 (0~59%)
    "warning": "#FB923C",    # 주황 (60~79%)
    "critical": "#EF4444",   # 빨강 (80~100%)
    "muted": "#9CA3AF",      # 회색 (비활성/null)
    "text": "#E5E7EB",       # 밝은 텍스트
    "subtext": "#6B7280",    # 서브 텍스트
}

# ═══════════════════════════════════════════════════
# SSL 컨텍스트 (macOS Python SSL 인증서 문제 해결)
# ═══════════════════════════════════════════════════

def _create_ssl_context():
    """SSL 컨텍스트 3단계 fallback"""
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        pass
    try:
        return ssl.create_default_context()
    except Exception:
        pass
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx

SSL_CONTEXT = _create_ssl_context()

# ═══════════════════════════════════════════════════
# 캐시 (429 대비 — React의 localStorage get/set에 해당)
# API 성공 시 저장, 429 시 꺼내 쓰기
# ═══════════════════════════════════════════════════

def load_cache() -> dict | None:
    """마지막 성공 데이터를 파일에서 읽기"""
    try:
        with open(CACHE_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return None

def save_cache(data: dict):
    """성공 데이터를 파일에 저장 (타임스탬프 포함)"""
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    # 캐시 저장 시각을 함께 기록
    data["_cached_at"] = datetime.now().isoformat()
    with open(CACHE_FILE, "w") as f:
        json.dump(data, f)

def format_cache_age(cached_at_str: str) -> str:
    """캐시 저장 시각 → '5분 전 데이터' 형태"""
    try:
        cached_at = datetime.fromisoformat(cached_at_str)
        delta = datetime.now() - cached_at
        minutes = int(delta.total_seconds() // 60)
        if minutes < 1:
            return "방금 전"
        elif minutes < 60:
            return f"{minutes}분 전"
        else:
            hours = minutes // 60
            return f"{hours}시간 {minutes % 60}분 전"
    except Exception:
        return "알 수 없음"

# ═══════════════════════════════════════════════════
# Keychain 접근 (macOS security 명령 사용)
# React로 치면 localStorage.getItem()에 해당
# ═══════════════════════════════════════════════════

def get_oauth_token() -> str | None:
    """macOS Keychain에서 Claude Code OAuth 토큰 추출"""
    try:
        # security 명령으로 Keychain 항목 읽기
        # -s: 서비스 이름, -w: 값만 출력 (패스워드 필드)
        result = subprocess.run(
            ["security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-w"],
            capture_output=True,
            text=True,
            timeout=5,
        )

        if result.returncode != 0:
            return None

        # JSON 파싱 → accessToken 추출
        # 구조: {"claudeAiOauth": {"accessToken": "sk-ant-oat01-...", ...}}
        creds = json.loads(result.stdout.strip())
        token = creds.get("claudeAiOauth", {}).get("accessToken")
        return token

    except json.JSONDecodeError:
        return None
    except subprocess.TimeoutExpired:
        return None
    except FileNotFoundError:
        # security 명령 없음 (Linux 등)
        return None
    except Exception:
        return None


# ═══════════════════════════════════════════════════
# API 호출
# ═══════════════════════════════════════════════════

def fetch_usage(token: str) -> dict:
    """OAuth 토큰으로 사용량 API 호출 (React의 fetch()에 해당)"""
    req = urllib.request.Request(API_URL)
    # Bearer 토큰 인증 (세션 쿠키와 다름!)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Accept", "application/json")
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "TokenGauge/1.0")
    # 이 헤더가 없으면 403 뜰 수 있음
    req.add_header("anthropic-beta", "oauth-2025-04-20")

    try:
        with urllib.request.urlopen(req, timeout=10, context=SSL_CONTEXT) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 401 or e.code == 403:
            return {"error": "token_expired"}
        return {"error": f"http_{e.code}"}
    except Exception as e:
        return {"error": str(e)}


# ═══════════════════════════════════════════════════
# 유틸리티 함수
# ═══════════════════════════════════════════════════

def get_color(utilization: float) -> str:
    """사용량 퍼센티지 → 색상"""
    if utilization >= THRESHOLD_CRITICAL:
        return COLORS["critical"]
    elif utilization >= THRESHOLD_WARNING:
        return COLORS["warning"]
    return COLORS["normal"]


def format_remaining(resets_at_str: str) -> str:
    """리셋 시각 → '2시간 30분 후' 형태"""
    if not resets_at_str:
        return "알 수 없음"
    try:
        resets_at = datetime.fromisoformat(resets_at_str)
        if resets_at.tzinfo is None:
            resets_at = resets_at.replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        delta = resets_at - now

        if delta.total_seconds() <= 0:
            return "곧 리셋"

        hours = int(delta.total_seconds() // 3600)
        minutes = int((delta.total_seconds() % 3600) // 60)

        if hours > 0:
            return f"{hours}시간 {minutes}분 후"
        return f"{minutes}분 후"
    except Exception:
        return "파싱 오류"


def progress_bar(pct: float, width: int = 20) -> str:
    """텍스트 프로그레스 바"""
    filled = int(pct / 100 * width)
    empty = width - filled
    return f"[{'█' * filled}{'░' * empty}]"


# ═══════════════════════════════════════════════════
# 렌더링 (SwiftBar 출력)
# ═══════════════════════════════════════════════════

def render_limit_section(label: str, data: dict | None, lines: list):
    """사용량 한도 섹션 렌더링 (React 컴포넌트 하나에 해당)"""
    if not data or data.get("utilization") is None:
        return

    pct = data["utilization"]
    color = get_color(pct)
    remaining = format_remaining(data.get("resets_at", ""))
    bar = progress_bar(pct)

    lines.append(f"{label} | color={COLORS['text']} size=13")
    lines.append(f"{bar}  {pct:.0f}% | color={color} font=Menlo size=12")
    lines.append(f"리셋: {remaining} | color={COLORS['subtext']} size=11")
    lines.append("---")


def render_menubar(usage: dict) -> str:
    """메뉴바 텍스트 (항상 보이는 부분)"""
    five = usage.get("five_hour")
    seven = usage.get("seven_day")

    if not five and not seven:
        return "TG: ⚠️"

    parts = []
    max_pct = 0

    if five and five.get("utilization") is not None:
        pct = five["utilization"]
        parts.append(f"5h:{pct:.0f}%")
        max_pct = max(max_pct, pct)

    if seven and seven.get("utilization") is not None:
        pct = seven["utilization"]
        parts.append(f"7d:{pct:.0f}%")
        max_pct = max(max_pct, pct)

    color = get_color(max_pct)
    return f"{' ǀ '.join(parts)} | color={color} size=12"


def render_dropdown(usage: dict, is_cached: bool = False) -> list:
    """드롭다운 메뉴 (클릭 시 펼쳐지는 부분)"""
    lines = []

    lines.append(f"TokenGauge | size=14 color={COLORS['text']}")
    lines.append("---")

    # 각 사용량 윈도우 렌더링
    render_limit_section("현재 세션 (5시간)", usage.get("five_hour"), lines)
    render_limit_section("주간 한도 — 모든 모델", usage.get("seven_day"), lines)
    render_limit_section("주간 한도 — Sonnet", usage.get("seven_day_sonnet"), lines)
    render_limit_section("주간 한도 — Opus", usage.get("seven_day_opus"), lines)

    # 추가 사용량
    extra = usage.get("extra_usage", {})
    if extra and extra.get("is_enabled"):
        lines.append(f"추가 사용량: 활성 | color={COLORS['normal']} size=12")
    else:
        lines.append(f"추가 사용량: 비활성 | color={COLORS['muted']} size=12")

    lines.append("---")

    # 푸터
    if is_cached:
        # 캐시 데이터일 때: 원래 데이터 시각 표시
        cached_at = usage.get("_cached_at", "")
        age_str = format_cache_age(cached_at) if cached_at else "알 수 없음"
        lines.append(f"⚠️ 캐시 데이터 ({age_str}) — API 제한 중 | color={COLORS['warning']} size=10")
    else:
        now_str = datetime.now().strftime("%H:%M:%S")
        lines.append(f"마지막 업데이트: {now_str} | color={COLORS['subtext']} size=10")

    lines.append("새로고침 | refresh=true")
    lines.append("---")
    lines.append("claude.ai 사용량 페이지 열기 | href=https://claude.ai/settings/usage")
    lines.append("TokenGauge GitHub | href=https://github.com/l2juhan/token-gauge")

    return lines


def render_error(error_type: str):
    """에러 상태 표시"""
    if error_type == "no_claude_code":
        print(f"TG: ⚙️ | color={COLORS['muted']}")
        print("---")
        print(f"Claude Code 인증 필요 | color={COLORS['text']} size=13")
        print("---")
        print("설정 방법: | color={COLORS['subtext']} size=11")
        print("--1. npm install -g @anthropic-ai/claude-code | color={COLORS['subtext']} size=11")
        print("--2. 터미널에서 'claude' 실행 후 로그인 | color={COLORS['subtext']} size=11")
        print("--3. SwiftBar 새로고침 | color={COLORS['subtext']} size=11")
    elif error_type == "token_expired":
        print(f"TG: 🔑 | color={COLORS['critical']}")
        print("---")
        print(f"OAuth 토큰 만료 | color={COLORS['critical']} size=13")
        print(f"Claude Code 재로그인 필요 | color={COLORS['subtext']} size=11")
        print("---")
        print("터미널에서 'claude' 실행 | color={COLORS['subtext']} size=11")
    else:
        print(f"TG: ❌ | color={COLORS['critical']}")
        print("---")
        print(f"오류: {error_type} | color={COLORS['critical']} size=13")
        print("새로고침 | refresh=true")


# ═══════════════════════════════════════════════════
# 메인 (React의 App 컴포넌트에 해당)
# ═══════════════════════════════════════════════════

def main():
    # 1. Keychain에서 토큰 읽기
    token = get_oauth_token()
    if not token:
        render_error("no_claude_code")
        return

    # 2. API 호출
    usage = fetch_usage(token)

    # 3. 에러 처리 (429면 캐시 fallback)
    if "error" in usage:
        if usage["error"] == "http_429":
            # 429 = rate limit → 마지막 성공 데이터로 대체
            cached = load_cache()
            if cached:
                print(render_menubar(cached))
                print("---")
                for line in render_dropdown(cached, is_cached=True):
                    print(line)
                return
        render_error(usage["error"])
        return

    # 4. 성공 시 캐시 저장 + 렌더링
    save_cache(usage)
    print(render_menubar(usage))
    print("---")
    for line in render_dropdown(usage):
        print(line)


if __name__ == "__main__":
    main()

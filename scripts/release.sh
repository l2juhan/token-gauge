#!/bin/bash
set -euo pipefail

# TokenGauge 릴리스 스크립트
# 사용법: ./scripts/release.sh <version> [--skip-notarize]

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="TokenGauge.xcodeproj"
SCHEME="TokenGauge"
APP_NAME="TokenGauge"
TEAM_ID="4XTGL2D5GF"

VERSION="${1:?사용법: ./scripts/release.sh <version> [--skip-notarize]}"
SKIP_NOTARIZE="${2:-}"

DIST_DIR="$PROJECT_DIR/dist"
ARCHIVE_PATH="$DIST_DIR/${APP_NAME}.xcarchive"
EXPORT_PATH="$DIST_DIR/export"
APP_PATH="$EXPORT_PATH/${APP_NAME}.app"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.zip"

echo "=== TokenGauge v${VERSION} 릴리스 빌드 ==="

# 정리
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 1. Archive
echo ">>> Archive 빌드 중..."
xcodebuild archive \
  -project "$PROJECT_DIR/$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$(date +%Y%m%d%H%M)" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  | tail -1

echo ">>> Archive 완료"

# 2. Export
echo ">>> Export 중..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$PROJECT_DIR/scripts/ExportOptions.plist" \
  -exportPath "$EXPORT_PATH" \
  | tail -1

echo ">>> Export 완료: $APP_PATH"

# 3. 공증 (Notarization)
if [ "$SKIP_NOTARIZE" != "--skip-notarize" ]; then
  echo ">>> 공증 제출 중..."

  # ZIP 생성 (공증용)
  ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

  xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "TokenGauge-notary" \
    --wait

  # Staple
  xcrun stapler staple "$APP_PATH"
  echo ">>> 공증 완료"
else
  echo ">>> 공증 건너뜀"
fi

# 4. DMG 생성
echo ">>> DMG 생성 중..."
STAGING="$DIST_DIR/dmg-staging"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING"

# DMG도 공증
if [ "$SKIP_NOTARIZE" != "--skip-notarize" ]; then
  echo ">>> DMG 공증 중..."
  xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "TokenGauge-notary" \
    --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo ">>> DMG 완료: $DMG_PATH"

# 5. SHA256
echo ""
echo "=== 릴리스 아티팩트 ==="
echo "DMG: $DMG_PATH"
echo "ZIP: $ZIP_PATH"
echo "SHA256 (DMG): $(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
echo "SHA256 (ZIP): $(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
echo ""
echo "=== v${VERSION} 릴리스 빌드 완료 ==="

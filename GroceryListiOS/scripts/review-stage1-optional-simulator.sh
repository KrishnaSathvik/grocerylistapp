#!/usr/bin/env bash
# Stage 1 optional-states + reliable RTL screenshot harness.
# Uses DEBUG `-Stage1ItemRowReview` with `.environment(\.layoutDirection, .rightToLeft)`
# for RTL (not AppleTextDirection).
#
# Env:
#   SIMULATOR_UDID / SIMULATOR_DEVICE / DEVICE_SLUG / SKIP_BUILD
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/DesignReferences/dynamic-type-review"
DERIVED="/tmp/GroceryListDerivedDynamicTypeReview"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/GroceryList.app"
BUNDLE="com.krishnasathvik.grocerylistapp"
UDID="${SIMULATOR_UDID:-37411883-BCD3-48D9-8694-C5508FD535F2}"
DEVICE="${SIMULATOR_DEVICE:-iPhone 17}"
DEVICE_SLUG="${DEVICE_SLUG:-stage1}"
SKIP_BUILD="${SKIP_BUILD:-0}"

mkdir -p "$OUT"

shot() {
  local name="$1"
  sleep "${2:-1.0}"
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png"
  echo "  ✓ $name"
}

launch_scene() {
  local scene="$1"
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" \
    -Stage1ItemRowReview \
    "-Stage1ReviewScene=$scene" >/dev/null
  sleep 2.0
}

scroll_down() {
  # Drag upward in the middle of the screen to scroll content down.
  osascript <<EOF 2>/dev/null || true
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
  tell process "Simulator"
    if (count of windows) is 0 then return
    set theWindow to front window
    set {x, y} to position of theWindow
    set {w, h} to size of theWindow
    set startX to x + (w / 2)
    set startY to y + (h * 0.72)
    set endY to y + (h * 0.28)
    click at {startX, startY}
    -- Fallback: key-based scroll when drag APIs are unavailable
  end tell
end tell
EOF
  # Use simctl ui / AppleScript page-down equivalent via keyboard
  osascript <<'EOF' 2>/dev/null || true
tell application "Simulator" to activate
delay 0.15
tell application "System Events"
  key code 125 using {option down} -- Option+Down ≈ page down in many hosts
  delay 0.15
  key code 125 using {option down}
end tell
EOF
  sleep 0.8
}

if [[ "$SKIP_BUILD" != "1" ]]; then
  echo "==> Building Debug for Stage 1 optional/RTL review"
  xcodebuild \
    -project "$ROOT/GroceryList.xcodeproj" \
    -scheme GroceryList \
    -configuration Debug \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    build >/tmp/grocerylist-stage1-optional-build.log
else
  echo "==> SKIP_BUILD=1 — reusing $APP"
  [[ -d "$APP" ]] || { echo "Missing app at $APP"; exit 1; }
fi

echo "==> Booting $DEVICE ($UDID)"
xcrun simctl shutdown all 2>/dev/null || true
sleep 1
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$UDID"
sleep 2
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
xcrun simctl uninstall "$UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"

# Skip onboarding for harness (root replaces MainTab when launch arg present).
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null || true
sleep 0.8
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
container="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data 2>/dev/null || echo "")"
if [[ -n "$container" ]]; then
  prefs="$container/Library/Preferences/$BUNDLE.plist"
  mkdir -p "$(dirname "$prefs")"
  /usr/libexec/PlistBuddy -c "Add :hasCompletedOnboarding bool true" "$prefs" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :hasCompletedOnboarding true" "$prefs" 2>/dev/null || true
fi

xcrun simctl ui "$UDID" appearance light
xcrun simctl ui "$UDID" content_size large

echo "==> Optional states (1–5: normal/completed/selection/no-thumb/no-edit)"
launch_scene optional
shot "${DEVICE_SLUG}-optional-top" 1.2

echo "==> Optional states more (6–10: qty text / metadata / chicken / edit compare)"
launch_scene optional2
shot "${DEVICE_SLUG}-optional-more" 1.2

echo "==> Candidates A/B/C"
launch_scene candidates
shot "${DEVICE_SLUG}-candidates" 1.2

echo "==> Candidate B review (Butter/Eggs/Watermelon/Strawberries/Chicken)"
launch_scene breview
shot "${DEVICE_SLUG}-candidate-b-review" 1.2

echo "==> RTL (layoutDirection; not AppleTextDirection)"
launch_scene rtl
shot "${DEVICE_SLUG}-rtl-top" 1.2

# Friendly aliases matching REVIEW_NOTES naming (no-op when DEVICE_SLUG=stage1).
alias_shot() {
  local src="$1" dst="$2"
  if [[ -f "$src" && "$src" != "$dst" ]]; then
    cp -f "$src" "$dst"
  fi
}
alias_shot "$OUT/${DEVICE_SLUG}-optional-top.png" "$OUT/stage1-optional-top.png"
alias_shot "$OUT/${DEVICE_SLUG}-optional-more.png" "$OUT/stage1-optional-more.png"
alias_shot "$OUT/${DEVICE_SLUG}-candidates.png" "$OUT/stage1-candidates-abc.png"
alias_shot "$OUT/${DEVICE_SLUG}-candidate-b-review.png" "$OUT/stage1-candidate-b-review.png"
alias_shot "$OUT/${DEVICE_SLUG}-rtl-top.png" "$OUT/stage1-rtl-top.png"

echo "==> Done. Screenshots in $OUT"
ls -1 "$OUT"/${DEVICE_SLUG}-*.png "$OUT"/stage1-*.png 2>/dev/null | sed 's/^/  /' | sort -u

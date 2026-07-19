#!/usr/bin/env bash
# Dynamic Type / Stage 1 ItemRow content-fit screenshot gate.
# Captures content-size × appearance × device matrix for list-detail ItemRows.
#
# Env:
#   SIMULATOR_UDID / SIMULATOR_DEVICE  — target simulator
#   DEVICE_SLUG                        — filename prefix (default: derived from device name)
#   REVIEW_MODE                        — priority | itemrow-sweep | cross-device | full-screens
#   CAPTURE_FOCUS                      — list-detail (default) | all
#   SKIP_BUILD=1                       — reuse existing DerivedData build
#   INCLUDE_RTL=1                      — capture one forced-RTL smoke shot
#
# Examples:
#   SIMULATOR_DEVICE="iPhone 17" SIMULATOR_UDID=... REVIEW_MODE=itemrow-sweep \
#     ./GroceryListiOS/scripts/review-dynamic-type-simulator.sh
#   SIMULATOR_DEVICE="iPhone 16e" SIMULATOR_UDID=... DEVICE_SLUG=iphone16e \
#     REVIEW_MODE=cross-device ./GroceryListiOS/scripts/review-dynamic-type-simulator.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/DesignReferences/dynamic-type-review"
DERIVED="/tmp/GroceryListDerivedDynamicTypeReview"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/GroceryList.app"
BUNDLE="com.krishnasathvik.grocerylistapp"
UDID="${SIMULATOR_UDID:-37411883-BCD3-48D9-8694-C5508FD535F2}"
DEVICE="${SIMULATOR_DEVICE:-iPhone 17}"
REVIEW_MODE="${REVIEW_MODE:-priority}"
CAPTURE_FOCUS="${CAPTURE_FOCUS:-list-detail}"
SKIP_BUILD="${SKIP_BUILD:-0}"
INCLUDE_RTL="${INCLUDE_RTL:-0}"
# When 1 (default), trust DEBUG auto-navigation into list detail and skip AX tree clicks.
# Set USE_AX_CLICKS=1 only if auto-open is unavailable.
USE_AX_CLICKS="${USE_AX_CLICKS:-0}"

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-$//'
}

DEVICE_SLUG="${DEVICE_SLUG:-$(slugify "$DEVICE")}"

mkdir -p "$OUT"

click_desc() {
  local desc="$1"
  osascript <<EOF 2>/dev/null || true
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
  tell process "Simulator"
    if (count of windows) is 0 then return
    set elems to entire contents of front window
    repeat with e in elems
      try
        if description of e is "$desc" then
          click e
          exit repeat
        end if
      end try
    end repeat
  end tell
end tell
EOF
}

click_containing() {
  local text="$1"
  osascript <<EOF 2>/dev/null || true
tell application "Simulator" to activate
delay 0.25
tell application "System Events"
  tell process "Simulator"
    if (count of windows) is 0 then return
    set elems to entire contents of front window
    repeat with e in elems
      try
        set v to value of e as text
        if v contains "$text" then
          click e
          exit repeat
        end if
      end try
      try
        set d to description of e as text
        if d contains "$text" then
          click e
          exit repeat
        end if
      end try
    end repeat
  end tell
end tell
EOF
}

set_content_size() {
  local category="$1"
  xcrun simctl ui "$UDID" content_size "$category"
  sleep 0.6
}

set_appearance() {
  local mode="$1"
  xcrun simctl ui "$UDID" appearance "$mode"
  sleep 0.4
}

shot() {
  local name="$1"
  sleep "${2:-0.9}"
  local attempt
  for attempt in 1 2 3; do
    if xcrun simctl io "$UDID" screenshot "$OUT/$name.png" 2>/dev/null; then
      echo "  ✓ $name"
      return 0
    fi
    echo "  … screenshot retry $attempt for $name"
    open -a Simulator --args -CurrentDeviceUDID "$UDID"
    sleep 1.2
  done
  echo "  ✗ failed screenshot $name" >&2
  return 1
}

launch_review_app() {
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" -B1ProduceReview >/dev/null
  # Allow DEBUG auto-navigation into B1 Produce Review detail.
  sleep 2.4
}

# Fresh installs always show onboarding; mark complete before review launches.
skip_onboarding() {
  xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null || true
  sleep 1.0
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  local container
  container="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data 2>/dev/null || echo "")"
  if [[ -n "$container" ]]; then
    local prefs="$container/Library/Preferences/$BUNDLE.plist"
    mkdir -p "$(dirname "$prefs")"
    /usr/libexec/PlistBuddy -c "Add :hasCompletedOnboarding bool true" "$prefs" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Set :hasCompletedOnboarding true" "$prefs" 2>/dev/null || true
  fi
}

open_review_list() {
  # Prefer DEBUG auto-open (MyListsView.onAppear). AX tree walks via osascript can hang.
  if [[ "$USE_AX_CLICKS" == "1" ]]; then
    click_desc "Skip onboarding" || true
    click_containing "Skip" || true
    sleep 0.3
    click_desc "Lists" || true
    sleep 0.6
    click_containing "B1 Produce Review" || true
    sleep 0.5
    click_containing "to buy" || true
  fi
  sleep 0.8
}

record_device_metrics() {
  local metrics_file="$OUT/device-metrics-${DEVICE_SLUG}.txt"
  {
    echo "device=$DEVICE"
    echo "udid=$UDID"
    echo "slug=$DEVICE_SLUG"
    echo "captured_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    # Screenshot pixel size after first capture; logical width filled later if available.
    if [[ -f "$OUT/${DEVICE_SLUG}-size-large-light-list-detail.png" ]]; then
      sips -g pixelWidth -g pixelHeight "$OUT/${DEVICE_SLUG}-size-large-light-list-detail.png" 2>/dev/null || true
    fi
  } >"$metrics_file"
  echo "==> Device metrics → $metrics_file"
}

# All 12 UIContentSizeCategory values accepted by simctl.
ALL_SIZES=(
  "size-x-small:extra-small"
  "size-small:small"
  "size-medium:medium"
  "size-large:large"
  "size-x-large:extra-large"
  "size-xx-large:extra-extra-large"
  "size-xxx-large:extra-extra-extra-large"
  "size-a11y-medium:accessibility-medium"
  "size-a11y-large:accessibility-large"
  "size-a11y-x-large:accessibility-extra-large"
  "size-a11y-xx-large:accessibility-extra-extra-large"
  "size-a11y-xxx-large:accessibility-extra-extra-extra-large"
)

CROSS_DEVICE_SIZES=(
  "size-x-small:extra-small"
  "size-large:large"
  "size-xxx-large:extra-extra-extra-large"
  "size-a11y-large:accessibility-large"
  "size-a11y-xxx-large:accessibility-extra-extra-extra-large"
)

# Dark required at least at Large + Accessibility XXXL (spec §10).
dark_required_for_size() {
  case "$1" in
    size-large|size-a11y-xxx-large) return 0 ;;
    *) return 1 ;;
  esac
}

appearances_for_size() {
  local size_slug="$1"
  local force_both="${2:-0}"
  if [[ "$force_both" == "1" ]] || dark_required_for_size "$size_slug"; then
    echo "light dark"
  else
    echo "light"
  fi
}

capture_list_detail() {
  local size_slug="$1"
  local appearance="$2"
  local prefix="${DEVICE_SLUG}-${size_slug}-${appearance}"

  set_appearance "$appearance"
  launch_review_app
  open_review_list
  shot "${prefix}-list-detail"
  # Second shot shortly after for row-focused alias used by reviewers.
  shot "${prefix}-list-detail-rows" 0.3
}

capture_all_screens() {
  local size_slug="$1"
  local appearance="$2"
  local prefix="${DEVICE_SLUG}-${size_slug}-${appearance}"

  set_appearance "$appearance"
  launch_review_app

  click_desc "Lists" || true
  sleep 1.0
  shot "${prefix}-my-lists"

  open_review_list
  shot "${prefix}-list-detail"
  shot "${prefix}-list-detail-rows" 0.3

  click_desc "Back to lists" || true
  sleep 0.8
  click_desc "Store" || click_desc "Stores" || true
  sleep 1.0
  shot "${prefix}-stores"

  click_desc "Categories" || true
  sleep 1.0
  shot "${prefix}-categories"

  click_desc "More" || true
  sleep 1.0
  shot "${prefix}-more-top"
  shot "${prefix}-more-preferences" 0.3
}

capture_size() {
  local size_slug="$1"
  local size_category="$2"
  local force_both_appearances="${3:-0}"

  set_content_size "$size_category"

  local appearance
  for appearance in $(appearances_for_size "$size_slug" "$force_both_appearances"); do
    if [[ "$CAPTURE_FOCUS" == "all" ]]; then
      capture_all_screens "$size_slug" "$appearance"
    else
      capture_list_detail "$size_slug" "$appearance"
    fi
  done
}

capture_size_list() {
  local force_both="${1:-0}"
  shift
  local entry size_slug size_category
  for entry in "$@"; do
    size_slug="${entry%%:*}"
    size_category="${entry#*:}"
    echo "==> $DEVICE_SLUG / $size_slug ($size_category)"
    capture_size "$size_slug" "$size_category" "$force_both"
  done
}

capture_rtl_smoke() {
  echo "==> RTL smoke (Accessibility Large / light)"
  set_appearance light
  set_content_size accessibility-large
  # Prefer right-to-left layout without changing system language permanently.
  xcrun simctl spawn "$UDID" defaults write "$BUNDLE" AppleTextDirection -bool YES 2>/dev/null || true
  xcrun simctl spawn "$UDID" defaults write NSGlobalDomain AppleTextDirection -bool YES 2>/dev/null || true
  launch_review_app
  open_review_list
  shot "${DEVICE_SLUG}-size-a11y-large-light-list-detail-rtl"
  xcrun simctl spawn "$UDID" defaults delete "$BUNDLE" AppleTextDirection 2>/dev/null || true
  xcrun simctl spawn "$UDID" defaults delete NSGlobalDomain AppleTextDirection 2>/dev/null || true
}

if [[ "$SKIP_BUILD" != "1" ]]; then
  echo "==> Building Debug for Dynamic Type review"
  xcodebuild \
    -project "$ROOT/GroceryList.xcodeproj" \
    -scheme GroceryList \
    -configuration Debug \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    build >/tmp/grocerylist-dynamic-type-build.log
else
  echo "==> SKIP_BUILD=1 — reusing $APP"
  [[ -d "$APP" ]] || { echo "Missing app at $APP"; exit 1; }
fi

echo "==> Booting $DEVICE ($UDID) alone"
xcrun simctl shutdown all 2>/dev/null || true
sleep 1
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$UDID"
sleep 2
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
xcrun simctl uninstall "$UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
skip_onboarding

echo "==> Capturing REVIEW_MODE=$REVIEW_MODE CAPTURE_FOCUS=$CAPTURE_FOCUS DEVICE_SLUG=$DEVICE_SLUG"
set_appearance light
set_content_size large

case "$REVIEW_MODE" in
  itemrow-sweep)
    # Complete 12-size sweep; dark at Large + AX XXXL via appearances_for_size.
    capture_size_list 0 "${ALL_SIZES[@]}"
    ;;
  cross-device)
    # Spec subset; force light+dark for every subset size so Large/AX XXXL (and others) covered.
    capture_size_list 1 "${CROSS_DEVICE_SIZES[@]}"
    ;;
  priority)
    # Task 5 prioritized matrix for the current device role:
    # - standard (iPhone 17): full 12-size light sweep (+ dark at Large / AX XXXL)
    # - narrow/wide: Large + AX XXXL light/dark (minimum); also capture remaining subset in light
    if [[ "$DEVICE_SLUG" == *"17" && "$DEVICE_SLUG" != *"pro"* && "$DEVICE_SLUG" != *"max"* && "$DEVICE_SLUG" != *"16e"* && "$DEVICE_SLUG" != *"17e"* ]]; then
      capture_size_list 0 "${ALL_SIZES[@]}"
    elif [[ "$DEVICE" == "iPhone 17" ]]; then
      capture_size_list 0 "${ALL_SIZES[@]}"
    else
      # Narrow / wide priority: Large + AX XXXL both appearances, plus light for other subset sizes.
      echo "==> Priority cross-device subset on $DEVICE"
      capture_size "size-large" "large" 1
      capture_size "size-a11y-xxx-large" "accessibility-extra-extra-extra-large" 1
      capture_size "size-x-small" "extra-small" 0
      capture_size "size-xxx-large" "extra-extra-extra-large" 0
      capture_size "size-a11y-large" "accessibility-large" 0
    fi
    ;;
  full-screens)
    CAPTURE_FOCUS=all
    # Legacy broader-screen matrix at four boundary sizes.
    capture_size_list 1 \
      "size-large:large" \
      "size-xxx-large:extra-extra-extra-large" \
      "size-a11y-large:accessibility-large" \
      "size-a11y-xxx-large:accessibility-extra-extra-extra-large"
    ;;
  *)
    echo "Unknown REVIEW_MODE=$REVIEW_MODE (use priority|itemrow-sweep|cross-device|full-screens)" >&2
    exit 1
    ;;
esac

if [[ "$INCLUDE_RTL" == "1" ]]; then
  capture_rtl_smoke
fi

# Restore defaults
set_appearance light
set_content_size large
record_device_metrics

echo "==> Done. Screenshots in $OUT (prefix ${DEVICE_SLUG}-*)"
ls -1 "$OUT"/${DEVICE_SLUG}-*.png 2>/dev/null | wc -l | awk '{print "  count:", $1}'
ls -1 "$OUT"/${DEVICE_SLUG}-*.png 2>/dev/null | sed 's/^/  /' | tail -40

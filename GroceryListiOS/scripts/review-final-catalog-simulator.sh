#!/usr/bin/env bash
# Final 182-asset catalog simulator review on iPhone Simulator.
# Captures light/dark, Dynamic Type, RTL, and grouping tabs for list rows.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/DesignReferences/asset-audit/final-catalog-simulator-review"
DERIVED="/tmp/GroceryListDerivedFinalCatalogReview"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/GroceryList.app"
BUNDLE="com.krishnasathvik.grocerylistapp"
UDID="${SIMULATOR_UDID:-0DCFE83B-FC71-49BC-820A-126E3CB648BE}"
DEVICE="${SIMULATOR_DEVICE:-iPhone 17 Pro}"

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

shot() {
  local name="$1"
  sleep "${2:-0.9}"
  xcrun simctl io booted screenshot "$OUT/$name.png"
  echo "  ✓ $name"
}

scroll_list() {
  osascript <<'EOF' 2>/dev/null || true
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
  tell process "Simulator"
    key code 125 using {command down}
    delay 0.15
    key code 125 using {command down}
    delay 0.15
    key code 125 using {command down}
  end tell
end tell
EOF
}

launch_review_app() {
  xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch booted "$BUNDLE" -FinalCatalogReview >/dev/null
  sleep 2.0
}

open_review_list() {
  # Auto-open should land in list detail; fall back to AX if needed.
  sleep 0.4
  click_desc "Lists" || true
  sleep 0.4
  click_containing "Final Catalog Review" || click_desc "Final Catalog Review" || true
  sleep 1.2
}

set_rtl() {
  local enabled="$1"
  if [[ "$enabled" == "1" ]]; then
    xcrun simctl spawn booted defaults write "$BUNDLE" AppleTextDirection -bool YES 2>/dev/null || true
    xcrun simctl spawn booted defaults write NSGlobalDomain AppleTextDirection -bool YES 2>/dev/null || true
  else
    xcrun simctl spawn booted defaults delete "$BUNDLE" AppleTextDirection 2>/dev/null || true
    xcrun simctl spawn booted defaults delete NSGlobalDomain AppleTextDirection 2>/dev/null || true
  fi
}

echo "==> Building Debug app..."
xcodebuild \
  -project "$ROOT/GroceryList.xcodeproj" \
  -scheme GroceryList \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED" \
  build \
  -quiet

echo "==> Booting $DEVICE..."
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$UDID"
sleep 2
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
xcrun simctl ui booted appearance light
xcrun simctl ui booted content_size large
set_rtl 0

echo "==> Fresh install..."
xcrun simctl uninstall booted "$BUNDLE" 2>/dev/null || true
xcrun simctl install booted "$APP"

# Skip onboarding before first launch
xcrun simctl launch booted "$BUNDLE" >/dev/null || true
sleep 1
xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
CONTAINER=$(xcrun simctl get_app_container booted "$BUNDLE" data 2>/dev/null || echo "")
if [[ -n "$CONTAINER" ]]; then
  PREFS="$CONTAINER/Library/Preferences/$BUNDLE.plist"
  mkdir -p "$(dirname "$PREFS")"
  /usr/libexec/PlistBuddy -c "Add :hasCompletedOnboarding bool true" "$PREFS" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :hasCompletedOnboarding true" "$PREFS" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :preferredColorScheme string system" "$PREFS" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :preferredColorScheme system" "$PREFS" 2>/dev/null || true
fi

echo "==> Light + large Dynamic Type..."
launch_review_app
open_review_list
shot "final-01-light-list-top" 1.0
scroll_list
shot "final-02-light-list-scrolled" 0.9
scroll_list
shot "final-03-light-list-bottom-checked" 0.9

click_desc "Stores"
shot "final-04-light-stores" 1.0
click_desc "Categories"
shot "final-05-light-categories" 1.0

# Try opening edit on a visible row (edit button / ellipsis).
click_desc "Lists" || true
sleep 0.3
click_containing "Final Catalog Review" || true
sleep 0.8
click_desc "Edit" || click_containing "Edit" || click_desc "More" || true
sleep 0.8
shot "final-06-light-edit-attempt" 0.8
# Dismiss any sheet
click_desc "Cancel" || click_desc "Done" || click_desc "Close" || true
sleep 0.5

echo "==> Dark mode..."
xcrun simctl ui booted appearance dark
sleep 0.5
launch_review_app
open_review_list
shot "final-07-dark-list-top" 1.0
scroll_list
shot "final-08-dark-list-scrolled" 0.9
click_desc "Categories"
shot "final-09-dark-categories" 1.0

echo "==> Accessibility-large Dynamic Type..."
xcrun simctl ui booted appearance light
xcrun simctl ui booted content_size accessibility-large
sleep 0.4
launch_review_app
open_review_list
shot "final-10-a11y-large-list" 1.0
scroll_list
shot "final-11-a11y-large-scrolled" 0.9

echo "==> Forced RTL smoke..."
xcrun simctl ui booted content_size large
set_rtl 1
launch_review_app
open_review_list
shot "final-12-rtl-list" 1.2
set_rtl 0

echo "==> Reset simulator UI..."
xcrun simctl ui booted content_size large
xcrun simctl ui booted appearance light

echo ""
echo "Screenshots saved to $OUT"
ls -1 "$OUT"/final-*.png | wc -l | xargs echo "Total captures:"
ls -1 "$OUT"/final-*.png

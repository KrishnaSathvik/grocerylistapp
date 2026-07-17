#!/usr/bin/env bash
# Interactive Phase B1 produce asset review on iPhone Simulator.
# Captures light/dark + Dynamic Type screenshots for list / Store / Categories.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/DesignReferences/asset-audit/b1-simulator-review"
DERIVED="/tmp/GroceryListDerivedB1Review"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/GroceryList.app"
BUNDLE="com.krishnasathvik.grocerylistapp"
UDID="${SIMULATOR_UDID:-0DCFE83B-FC71-49BC-820A-126E3CB648BE}"
DEVICE="${SIMULATOR_DEVICE:-iPhone 17 Pro}"

mkdir -p "$OUT"

click_desc() {
  local desc="$1"
  osascript <<EOF
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
  tell process "Simulator"
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

click_static() {
  local text="$1"
  osascript <<EOF
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
  tell process "Simulator"
    set elems to entire contents of front window
    repeat with e in elems
      try
        if value of e is "$text" then
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
  osascript <<EOF
tell application "Simulator" to activate
delay 0.25
tell application "System Events"
  tell process "Simulator"
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
  sleep "${2:-0.8}"
  xcrun simctl io booted screenshot "$OUT/$name.png"
  echo "  ✓ $name"
}

launch_review_app() {
  xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch booted "$BUNDLE" -B1ProduceReview >/dev/null
  sleep 1.8
}

open_review_list() {
  click_desc "Lists" || true
  sleep 0.5
  click_containing "B1 Produce Review" || click_static "B1 Produce Review" || click_desc "B1 Produce Review" || true
  sleep 1.4
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
xcrun simctl ui booted appearance light
xcrun simctl ui booted content_size large

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

echo "==> Light + normal Dynamic Type..."
launch_review_app
open_review_list
shot "b1-01-light-list-top" 1.0

# Scroll to see more produce rows
osascript <<'EOF' 2>/dev/null || true
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
  tell process "Simulator"
    key code 125 using {command down}
    delay 0.15
    key code 125 using {command down}
  end tell
end tell
EOF
shot "b1-02-light-list-scrolled" 0.9

click_desc "Stores"
shot "b1-03-light-store" 1.0
click_desc "Categories"
shot "b1-04-light-categories" 1.0

echo "==> Dark mode..."
xcrun simctl ui booted appearance dark
sleep 0.5
launch_review_app
open_review_list
shot "b1-05-dark-list" 1.0
click_desc "Stores"
shot "b1-06-dark-store" 1.0
click_desc "Categories"
shot "b1-07-dark-categories" 1.0

echo "==> Larger Dynamic Type (accessibility-large)..."
xcrun simctl ui booted appearance light
xcrun simctl ui booted content_size accessibility-large
sleep 0.4
launch_review_app
open_review_list
shot "b1-08-a11y-large-list" 1.0
click_desc "Stores"
shot "b1-09-a11y-large-store" 1.0
click_desc "Categories"
shot "b1-10-a11y-large-categories" 1.0

echo "==> Reset simulator UI..."
xcrun simctl ui booted content_size large
xcrun simctl ui booted appearance light

echo ""
echo "Screenshots saved to $OUT"
ls -1 "$OUT"/b1-*.png | wc -l | xargs echo "Total captures:"
ls -1 "$OUT"/b1-*.png

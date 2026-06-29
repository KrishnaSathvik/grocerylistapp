#!/usr/bin/env bash
# Captures visual QA screenshots from iPhone 17 Pro simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/ScreenshotReport"
APP="/tmp/GroceryListDerived/Build/Products/Debug-iphonesimulator/GroceryList.app"
BUNDLE="com.grocerylist.app"
UDID="${SIMULATOR_UDID:-0DCFE83B-FC71-49BC-820A-126E3CB648BE}"
DEVICE="${SIMULATOR_DEVICE:-iPhone 17 Pro}"

mkdir -p "$OUT"

click_desc() {
  local desc="$1"
  osascript <<EOF
tell application "Simulator" to activate
delay 0.25
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
delay 0.25
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

press_escape() {
  osascript -e 'tell application "System Events" to key code 53' 2>/dev/null || true
}

tab_bar() {
  local name="$1"
  click_desc "$name"
}

shot() {
  local name="$1"
  sleep "${2:-0.7}"
  xcrun simctl io booted screenshot "$OUT/$name.png"
  echo "  ✓ $name"
}

echo "Booting $DEVICE ($UDID)..."
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$UDID"
sleep 2

echo "Installing app (fresh)..."
xcrun simctl uninstall booted "$BUNDLE" 2>/dev/null || true
xcrun simctl install booted "$APP"
xcrun simctl launch booted "$BUNDLE" >/dev/null
sleep 2

echo "Onboarding (light)..."
shot "qa-01-onboarding-smart-lists" 1.2
click_desc "Next"
shot "qa-02-onboarding-add-naturally" 1.8
click_desc "Next"
shot "qa-03-onboarding-stay-organized" 2.0
click_desc "Next"
shot "qa-04-onboarding-share-import" 1.2

echo "My Lists empty..."
click_desc "Start my list"
sleep 1
shot "qa-05-my-lists-empty" 1

echo "Template list..."
click_desc "Create Weekly Groceries list"
sleep 1.2
shot "qa-07-list-detail-empty" 1

echo "Add Item from starter chip..."
click_desc "Try adding 2 eggs from Walmart"
sleep 1
shot "qa-08-add-item-from-chip" 0.8
press_escape
sleep 0.5

echo "Back to My Lists..."
press_escape
sleep 0.6
tab_bar "Lists"
shot "qa-06-my-lists-with-template" 0.8

echo "Store & Categories..."
tab_bar "Store"
shot "qa-09-store-empty" 1
click_desc "Add custom store"
sleep 0.8
shot "qa-11-add-custom-store" 0.8
press_escape
sleep 0.5
tab_bar "Categories"
shot "qa-10-categories-empty" 1

echo "Settings & secondary..."
tab_bar "More"
shot "qa-12-settings" 0.8

# Plus button on My Lists for create sheet
tab_bar "Lists"
sleep 0.5
click_desc "Create list"
sleep 0.8
shot "qa-13-create-list-sheet" 0.8
press_escape
sleep 0.5

tab_bar "More"
sleep 0.5
click_static "Export Data"
sleep 0.8
shot "qa-15-import-export" 0.8
press_escape
sleep 0.5

tab_bar "More"
sleep 0.5
click_static "Category Order"
sleep 0.8
shot "qa-16-category-order" 0.8
press_escape
sleep 0.5

tab_bar "Lists"
sleep 0.5
click_static "Weekly Groceries"
sleep 1
click_desc "Share list"
sleep 0.8
shot "qa-14-share-list" 0.8
press_escape
sleep 0.4
press_escape
sleep 0.4

echo "Dark mode..."
tab_bar "More"
sleep 0.5
click_static "Appearance"
sleep 0.5
click_static "Dark"
sleep 0.5
press_escape
sleep 0.8
shot "qa-20-dark-settings" 0.8

xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
CONTAINER=$(xcrun simctl get_app_container booted "$BUNDLE" data 2>/dev/null || echo "")
if [[ -n "$CONTAINER" && -f "$CONTAINER/Library/Preferences/$BUNDLE.plist" ]]; then
  plutil -replace hasCompletedOnboarding -bool false "$CONTAINER/Library/Preferences/$BUNDLE.plist" 2>/dev/null || true
  plutil -replace preferredColorScheme -string dark "$CONTAINER/Library/Preferences/$BUNDLE.plist" 2>/dev/null || true
fi
xcrun simctl launch booted "$BUNDLE" >/dev/null
sleep 1.5
shot "qa-17-dark-onboarding" 1.2

if [[ -n "$CONTAINER" && -f "$CONTAINER/Library/Preferences/$BUNDLE.plist" ]]; then
  plutil -replace hasCompletedOnboarding -bool true "$CONTAINER/Library/Preferences/$BUNDLE.plist" 2>/dev/null || true
fi
xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
xcrun simctl launch booted "$BUNDLE" >/dev/null
sleep 1.2
tab_bar "Lists"
shot "qa-18-dark-my-lists" 0.8
click_static "Weekly Groceries"
sleep 1
shot "qa-19-dark-list-detail" 0.8

echo ""
echo "Screenshots saved to $OUT"
ls -1 "$OUT"/qa-*.png 2>/dev/null | wc -l | xargs echo "Total captures:"

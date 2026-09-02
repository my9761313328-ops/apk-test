#!/usr/bin/env bash
set -e

APK="$(find "$GITHUB_WORKSPACE" -type f -name '*.apk' -print -quit)"

if [ -z "$APK" ]; then
  echo "ERROR: No APK file found in repository."
  exit 1
fi

echo "APK: $APK"

ADB="${ANDROID_HOME}/platform-tools/adb"
AAPT="$(find "${ANDROID_HOME}/build-tools" -type f -name aapt -print | sort -V | tail -n 1)"

if [ ! -x "$ADB" ]; then
  echo "ERROR: adb not found: $ADB"
  exit 1
fi

if [ -z "$AAPT" ]; then
  echo "ERROR: aapt not found in Android SDK build-tools."
  exit 1
fi

PACKAGE="$($AAPT dump badging "$APK" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)"

if [ -z "$PACKAGE" ]; then
  echo "ERROR: Could not read APK package name."
  exit 1
fi

echo "Package: $PACKAGE"

echo "Installing APK..."
"$ADB" install -r "$APK"

# Launch the application's MAIN/LAUNCHER activity without hard-coding its activity name.
echo "Launching APK..."
"$ADB" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true

sleep 3

echo "Recording screen for 60 seconds..."
rm -f "$GITHUB_WORKSPACE/recording-60s.mp4"
"$ADB" shell screenrecord --bit-rate 8000000 --time-limit 60 /sdcard/recording-60s.mp4
"$ADB" pull /sdcard/recording-60s.mp4 "$GITHUB_WORKSPACE/recording-60s.mp4"
"$ADB" shell rm -f /sdcard/recording-60s.mp4

# Save emulator logs for troubleshooting.
"$ADB" logcat -d > "$GITHUB_WORKSPACE/logcat.txt" || true

echo "Recording saved to $GITHUB_WORKSPACE/recording-60s.mp4"
ls -lh "$GITHUB_WORKSPACE/recording-60s.mp4"

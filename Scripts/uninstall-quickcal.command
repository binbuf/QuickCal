#!/bin/bash
#
# QuickCal Uninstaller
# Double-click this file to completely remove QuickCal from your Mac.
#

BUNDLE_ID="com.binbuf.QuickCal"
APP_NAME="QuickCal"
APP_PATH="/Applications/QuickCal.app"

echo "==============================="
echo "  QuickCal Uninstaller"
echo "==============================="
echo ""

# 1. Stop the app if running
echo "[1/6] Stopping QuickCal..."
if pgrep -x "$APP_NAME" > /dev/null 2>&1; then
    killall "$APP_NAME" 2>/dev/null
    sleep 1
    echo "      Stopped."
else
    echo "      Not running."
fi

# 2. Revoke Accessibility permission
echo "[2/6] Revoking Accessibility permission..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null
echo "      Done."

# 3. Remove login item (SMAppService entries are cleaned up with the app,
#    but we also reset the background task management database)
echo "[3/6] Removing login item..."
sfltool resetbtm 2>/dev/null
echo "      Done."

# 4. Delete preferences
echo "[4/6] Removing preferences..."
defaults delete "$BUNDLE_ID" 2>/dev/null
echo "      Done."

# 5. Remove application support and caches
echo "[5/6] Removing application data..."
rm -rf "$HOME/Library/Application Support/QuickCal" 2>/dev/null
rm -rf "$HOME/Library/Caches/$BUNDLE_ID" 2>/dev/null
rm -rf "$HOME/Library/HTTPStorages/$BUNDLE_ID" 2>/dev/null
rm -rf "$HOME/Library/Saved Application State/${BUNDLE_ID}.savedState" 2>/dev/null
echo "      Done."

# 6. Delete the app bundle
echo "[6/6] Removing application..."
if [ -d "$APP_PATH" ]; then
    rm -rf "$APP_PATH"
    echo "      Removed $APP_PATH"
else
    echo "      $APP_PATH not found."
    echo "      If you installed QuickCal elsewhere, please delete it manually."
fi

echo ""
echo "==============================="
echo "  QuickCal has been removed."
echo "==============================="
echo ""
echo "You can close this window."
echo ""

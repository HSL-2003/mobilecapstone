#!/bin/bash

echo "===================================="
echo "Getting SHA-1 Fingerprint for Android"
echo "===================================="
echo ""

# Get debug keystore SHA-1
echo "[DEBUG KEYSTORE]"
echo "Getting SHA-1 from debug keystore..."

DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ -f "$DEBUG_KEYSTORE" ]; then
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android
    echo ""
    echo "===================================="
    echo "IMPORTANT: Copy the SHA1 value above"
    echo "Add it to Firebase Console:"
    echo "1. Go to Firebase Console"
    echo "2. Select your project"
    echo "3. Project Settings > Your apps > Android app"
    echo "4. Add SHA certificate fingerprint"
    echo "===================================="
else
    echo "ERROR: Could not find debug keystore at: $DEBUG_KEYSTORE"
    echo ""
    echo "Make sure you have:"
    echo "1. Built the app at least once"
    echo "2. Or create the keystore manually"
fi

echo ""


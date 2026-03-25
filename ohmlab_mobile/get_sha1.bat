@echo off
echo ====================================
echo Getting SHA-1 Fingerprint for Android
echo ====================================
echo.

REM Get debug keystore SHA-1
echo [DEBUG KEYSTORE]
echo Getting SHA-1 from debug keystore...
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>nul

if errorlevel 1 (
    echo.
    echo ERROR: Could not find debug keystore at: %USERPROFILE%\.android\debug.keystore
    echo.
    echo Make sure you have:
    echo 1. Built the app at least once
    echo 2. Or create the keystore manually
) else (
    echo.
    echo ====================================
    echo IMPORTANT: Copy the SHA1 value above
    echo Add it to Firebase Console:
    echo 1. Go to Firebase Console
    echo 2. Select your project
    echo 3. Project Settings > Your apps > Android app
    echo 4. Add SHA certificate fingerprint
    echo ====================================
)

echo.
pause


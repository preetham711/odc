@echo off
echo ========================================
echo   Deploying Firestore Rules
echo ========================================
echo.

echo Checking Firebase CLI installation...
firebase --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Firebase CLI not installed!
    echo.
    echo Please install Firebase CLI first:
    echo npm install -g firebase-tools
    echo.
    echo Then run: firebase login
    pause
    exit /b 1
)

echo Firebase CLI found!
echo.

echo Checking if logged in to Firebase...
firebase projects:list >nul 2>&1
if errorlevel 1 (
    echo You need to login to Firebase first.
    echo.
    echo Running: firebase login
    firebase login
    if errorlevel 1 (
        echo Login failed!
        pause
        exit /b 1
    )
)

echo.
echo Deploying Firestore rules...
echo.
firebase deploy --only firestore:rules

if errorlevel 1 (
    echo.
    echo ========================================
    echo   DEPLOYMENT FAILED!
    echo ========================================
    echo.
    echo If you get a timeout error, you can:
    echo 1. Deploy manually via Firebase Console
    echo 2. Copy the content from firestore.rules
    echo 3. Paste into Firebase Console -^> Firestore Database -^> Rules
    echo 4. Click Publish
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo ========================================
    echo   DEPLOYMENT SUCCESS!
    echo ========================================
    echo.
    echo Firestore rules have been deployed successfully.
    echo Your app can now:
    echo - Create new user accounts
    echo - Store and fetch attendance data
    echo - Manage leave requests
    echo - Generate monthly reports
    echo.
    echo Next step: Test your app at https://odc-ten.vercel.app
    echo.
    pause
)

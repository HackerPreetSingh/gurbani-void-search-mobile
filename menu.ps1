# Interactive Build and Deploy Menu for Flutter App

function Show-Menu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   Gurbani Search - Build & Deploy Menu   " -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "1. Clean & Fetch Dependencies (flutter clean & pub get)" -ForegroundColor Green
    Write-Host "2. Build Shareable Android APK (.apk)" -ForegroundColor Green
    Write-Host "3. Build Web & Deploy to Firebase Hosting" -ForegroundColor Green
    Write-Host "4. Build Play Store App Bundle (.aab)" -ForegroundColor Green
    Write-Host "5. Exit" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Cyan
}

function Run-CleanAndPubGet {
    Write-Host "`n[1/2] Running 'flutter clean'..." -ForegroundColor Cyan
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clean flutter project." -ForegroundColor Red
        return $false
    }

    Write-Host "`n[2/2] Running 'flutter pub get'..." -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to get pub dependencies." -ForegroundColor Red
        return $false
    }

    Write-Host "`nSuccessfully cleaned and fetched dependencies!" -ForegroundColor Green
    return $true
}

function Pause-Console {
    Write-Host "`nPress Any Key to Return to Menu..." -ForegroundColor Gray
    [void][System.Console]::ReadKey($true)
}

do {
    Show-Menu
    $choice = Read-Host "Select an option (1-5)"

    switch ($choice) {
        '1' {
            [void](Run-CleanAndPubGet)
            Pause-Console
        }
        '2' {
            if (Run-CleanAndPubGet) {
                Write-Host "`nBuilding Shareable Android Release APK (.apk)..." -ForegroundColor Cyan
                flutter build apk --release
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`nShareable APK built successfully!" -ForegroundColor Green
                    Write-Host "Location: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Yellow
                } else {
                    Write-Host "`nFailed to build APK." -ForegroundColor Red
                }
            }
            Pause-Console
        }
        '3' {
            if (Run-CleanAndPubGet) {
                Write-Host "`nBuilding Web App for Firebase Hosting..." -ForegroundColor Cyan
                flutter build web
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`nDeploying to Firebase Hosting..." -ForegroundColor Cyan
                    firebase deploy --only hosting
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "`nSuccessfully deployed to Firebase Hosting!" -ForegroundColor Green
                    } else {
                        Write-Host "`nFirebase deployment failed." -ForegroundColor Red
                    }
                } else {
                    Write-Host "`nFailed to build Web App." -ForegroundColor Red
                }
            }
            Pause-Console
        }
        '4' {
            if (Run-CleanAndPubGet) {
                Write-Host "`nBuilding Play Store Android App Bundle (.aab)..." -ForegroundColor Cyan
                flutter build appbundle --release
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`nPlay Store App Bundle (.aab) built successfully!" -ForegroundColor Green
                    Write-Host "Location: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Yellow
                } else {
                    Write-Host "`nFailed to build App Bundle." -ForegroundColor Red
                }
            }
            Pause-Console
        }
        '5' {
            Write-Host "`nExiting menu. Waheguru Ji Ka Khalsa, Waheguru Ji Ki Fateh!" -ForegroundColor Yellow
            break
        }
        default {
            Write-Host "`nInvalid choice. Please select an option between 1 and 5." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne '5')

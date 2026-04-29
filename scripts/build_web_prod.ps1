param()
$envFile = ".env.prod"
if (Test-Path $envFile) {
    Write-Host "Loading $envFile"
    Get-Content $envFile | ForEach-Object {
        if ($_ -and -not ($_.TrimStart()).StartsWith('#')) {
            $parts = $_ -split '=',2
            if ($parts.Count -eq 2) {
                $name = $parts[0].Trim()
                $value = $parts[1].Trim()
                [System.Environment]::SetEnvironmentVariable($name, $value)
            }
        }
    }
}

$defines = @("--dart-define=FLAVOR=prod")
if ($env:API_URL) { $defines += "--dart-define=API_URL=$env:API_URL" }
if ($env:FIREBASE_API_KEY) { $defines += "--dart-define=FIREBASE_API_KEY=$env:FIREBASE_API_KEY" }
if ($env:FIREBASE_APP_ID) { $defines += "--dart-define=FIREBASE_APP_ID=$env:FIREBASE_APP_ID" }
if ($env:FIREBASE_MEASUREMENT_ID) { $defines += "--dart-define=FIREBASE_MEASUREMENT_ID=$env:FIREBASE_MEASUREMENT_ID" }
if ($env:FIREBASE_PROJECT_ID) { $defines += "--dart-define=FIREBASE_PROJECT_ID=$env:FIREBASE_PROJECT_ID" }

Write-Host "Running: flutter build web $($defines -join ' ')"
flutter build web --release --pwa-strategy=offline-first $defines

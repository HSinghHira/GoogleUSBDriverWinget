#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

$DriverUrl   = "https://dl.google.com/android/repository/usb_driver_r13-windows.zip"
$TempDir     = Join-Path $env:TEMP "GoogleUSBDriverInstall"
$ZipPath     = Join-Path $TempDir "usb_driver.zip"
$ExtractPath = Join-Path $TempDir "extracted"
$InfPath     = Join-Path $ExtractPath "usb_driver\android_winusb.inf"

# Prepare working directory
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

# Download driver
try {
    Invoke-WebRequest -Uri $DriverUrl -OutFile $ZipPath -UseBasicParsing
} catch {
    exit 1
}
if (!(Test-Path $ZipPath)) { exit 1 }

# Extract archive
Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
if (!(Test-Path $InfPath)) { exit 1 }

# Install driver
$process = Start-Process -FilePath "pnputil.exe" `
    -ArgumentList "/add-driver `"$InfPath`" /install" `
    -Wait -PassThru -NoNewWindow

# Cleanup
try { Remove-Item $TempDir -Recurse -Force } catch {}

# Exit with pnputil's code (0 = success, 259 = staged/no device present = also success)
if ($process.ExitCode -eq 259) { exit 0 }
exit $process.ExitCode
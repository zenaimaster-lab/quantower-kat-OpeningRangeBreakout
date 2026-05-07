# Deploy to MetaTrader and compile
$src = "c:\Users\kieuanhtuan\Documents\all. Coding\mt5-kat-ORB"
$dst = "C:\Users\kieuanhtuan\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\KAT ORB Breakout"
$mql5Root = "C:\Users\kieuanhtuan\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
$compiler = "C:\Program Files\MetaTrader 5\MetaEditor64.exe"

# Step 1: Copy source files
Copy-Item "$src\*.mq5" "$dst\" -Force
Copy-Item "$src\*.mqh" "$dst\" -Force
Write-Host "[DEPLOY] Files copied to MetaTrader" -ForegroundColor Green

# Step 2: Compile
$logFile = "$dst\compile_log.txt"
Start-Process -FilePath $compiler -ArgumentList "/compile:`"$dst\mt5-kat-ORB.mq5`" /log:`"$logFile`" /include:`"$mql5Root`"" -Wait -NoNewWindow
Start-Sleep -Seconds 2

# Step 3: Show result
if (Test-Path $logFile) {
    $content = Get-Content $logFile -Encoding Unicode
    $result = $content | Where-Object { $_ -match "^Result:" } | Select-Object -Last 1
    if ($result -match "0 errors") {
        Write-Host "[COMPILE] $result" -ForegroundColor Green
    } else {
        Write-Host "[COMPILE] $result" -ForegroundColor Red
        $content | Where-Object { $_ -match "error" } | Select-Object -Last 10
    }
} else {
    Write-Host "[COMPILE] No log file generated" -ForegroundColor Yellow
}

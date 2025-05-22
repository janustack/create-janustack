$bitness = if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq "X64") {
    "x86_64"
} elseif ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq "Arm64") {
    "aarch64"
} else {
    "i686"
}
$__TAG_NAME__ = "create-janustack"
$url="https://create.janustack/download/bin?tag=$__TAG_NAME__&arch=$bitness-pc-windows-msvc&ext=.exe"
$outFile = "$Env:TEMP\create-janustack.exe"

Write-Output "$($PSStyle.Bold)$($PSStyle.Foreground.Green)info:$($PSStyle.Reset) downloading create-janustack"

$oldProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $url -OutFile $outFile
$ProgressPreference = $oldProgressPreference

if ($Env:CTA_ARGS) {
    Start-Process -FilePath $outFile -Wait -NoNewWindow -ArgumentList "$Env:CTA_ARGS"
} else {
    Start-Process -FilePath $outFile -Wait -NoNewWindow
}
# Set GitHub repo root (DO NOT point to subfolders)
$repoUrl = "https://github.com/janustack/create-janustack.git"
$tempDir = "$env:TEMP\janustack-create"

# Step 1: Ask which template to use
$templates = @("next", "react", "solid")
Write-Host "Select a template:" -ForegroundColor Cyan
for ($i = 0; $i -lt $templates.Count; $i++) {
    Write-Host "[$($i + 1)] $($templates[$i])"
}
$templateIndex = Read-Host "Enter the number of the template you want"
$templateName = $templates[$templateIndex - 1]

if (-not $templateName) {
    Write-Error "Invalid selection. Exiting..."
    exit 1
}

# Step 2: Clone the entire repo shallowly
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
git clone --depth=1 $repoUrl $tempDir

# Step 3: Copy the template from crates/create/templates/
$src = Join-Path $tempDir "crates\create\templates\$templateName"
$dest = Get-Location

if (-not (Test-Path $src)) {
    Write-Error "Template '$templateName' not found at path: $src"
    exit 1
}

Copy-Item "$src\*" $dest -Recurse -Force

# Step 4: Clean up cloned repo
Remove-Item $tempDir -Recurse -Force

Write-Host "`n✅ Template '$templateName' installed successfully from crates/create/templates." -ForegroundColor Green

# Configuration
$repoUrl = "https://github.com/janustack/create-janustack.git"
$tempDir = "$env:TEMP\janustack-create"

# Step 1: Prompt for template selection
$templates = @("react", "next", "solid")
Write-Host "Select a template to create:" -ForegroundColor Cyan
for ($i = 0; $i -lt $templates.Count; $i++) {
    Write-Host "[$($i + 1)] $($templates[$i])"
}
$templateIndex = Read-Host "Enter the number of the template you want"
$templateName = $templates[$templateIndex - 1]

if (-not $templateName) {
    Write-Error "Invalid selection. Exiting..."
    exit 1
}

# Step 2: Clone repo
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
git clone --depth=1 $repoUrl $tempDir

# Step 3: Set paths
$templateSrc = Join-Path $tempDir "crates\create\templates\$templateName"
$sharedSrc = Join-Path $tempDir "crates\create\templates\shared"
$dest = Join-Path (Get-Location) $templateName

if (-not (Test-Path $templateSrc)) {
    Write-Error "Template '$templateName' not found."
    exit 1
}

# Step 4: Create destination folder
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# Step 5: Copy template
Copy-Item "$templateSrc\*" $dest -Recurse -Force

# Step 6: Conditionally copy shared if template is react or solid
if ($templateName -eq "react" -or $templateName -eq "solid") {
    if (Test-Path $sharedSrc) {
        Copy-Item "$sharedSrc\*" $dest -Recurse -Force
    }
    else {
        Write-Warning "Shared folder not found — skipping shared files."
    }
}

# Step 7: Cleanup
Remove-Item $tempDir -Recurse -Force

# Done
Write-Host "`n✅ '$templateName' template created at: $dest" -ForegroundColor Green

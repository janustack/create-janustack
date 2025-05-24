# Configuration
$repoUrl = "https://github.com/janustack/create-janustack.git"
$tempDir = "$env:TEMP\janustack-create"

# Step 1: Prompt for template selection
$mainTemplates = @("Janext", "Janudocs")
Write-Host "Select a template category:" -ForegroundColor Cyan
for ($i = 0; $i -lt $mainTemplates.Count; $i++) {
    Write-Host "[$($i + 1)] $($mainTemplates[$i])"
}
$mainIndex = Read-Host "Enter the number of your choice"
$mainTemplate = $mainTemplates[$mainIndex - 1]

if (-not $mainTemplate) {
    Write-Error "Invalid selection. Please enter a number from the list."
    return
}

# Step 2: Prompt for project name
$projectName = ""
while ([string]::IsNullOrWhiteSpace($projectName)) {
    $projectName = Read-Host "Enter the name for your new project (relative to current directory)"
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        Write-Warning "Project name cannot be empty."
    }
}

# Step 3: If Janudocs, prompt for React or Solid
if ($mainTemplate -eq "Janudocs") {
    $subTemplates = @("react", "solid")
    Write-Host "Select a Janudocs template:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $subTemplates.Count; $i++) {
        Write-Host "[$($i + 1)] $($subTemplates[$i])"
    }
    $subIndex = Read-Host "Enter the number of the sub-template you want"
    $subTemplate = $subTemplates[$subIndex - 1]

    if (-not $subTemplate) {
        Write-Error "Invalid selection. Exiting..."
        exit 1
    }
}

# Step 4: Clone the repo
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
git clone --depth=1 $repoUrl $tempDir

# Step 5: Determine template source path
if ($mainTemplate -eq "Janext") {
    $templateSrc = Join-Path $tempDir "templates\Janext"
    $destName = "janext"
} else {
    $templateSrc = Join-Path $tempDir "templates\Janudocs\$subTemplate"
    $sharedSrc = Join-Path $tempDir "templates\Janudocs\shared"
    $destName = "janudocs-$subTemplate"
}

$dest = Join-Path (Get-Location) $destName

if (-not (Test-Path $templateSrc)) {
    Write-Error "Template path not found: $templateSrc"
    exit 1
}

# Step 6: Create destination directory
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# Step 7: Copy template files
Copy-Item "$templateSrc\*" $dest -Recurse -Force

# Step 8: Copy shared files if Janudocs
if ($mainTemplate -eq "Janudocs" -and (Test-Path $sharedSrc)) {
    Copy-Item "$sharedSrc\*" $dest -Recurse -Force
}

# Step 9: Cleanup
Remove-Item $tempDir -Recurse -Force

# Done
Write-Host "`n✅ Project '$projectName' (using $chosenTemplateFramework template) scaffolded successfully!" -ForegroundColor Green
Write-Host "   Your new project is located at: $destinationPath" -ForegroundColor Green
Write-Host "`nTo get started, navigate to your project directory:" -ForegroundColor Cyan
Write-Host "cd '$projectName'"

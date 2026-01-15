#!/usr/bin/env pwsh
<#
.SYNOPSIS
Automated GitHub Template Test Suite

.DESCRIPTION
Complete end-to-end test of the Clean Architecture API Template from GitHub

.PARAMETER RepoUrl
GitHub repository URL (default: official repository)

.PARAMETER TestBase
Base directory for test projects (default: C:\temp\github-template-test)

.EXAMPLE
.\test-github-template.ps1

.\test-github-template.ps1 -TestBase "D:\MyTests"
#>

param(
    [string]$RepoUrl = "https://github.com/tharper1977-templates/ApiTemplate.git",
    [string]$TestBase = "C:\temp\github-template-test"
)

$ErrorActionPreference = "Continue"
$testResults = @()
$startTime = Get-Date

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "??????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host "? $($Text.PadRight(50)) ?" -ForegroundColor Cyan
    Write-Host "??????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host ""
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $status = if ($Passed) { "? PASS" } else { "? FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status - $TestName" -ForegroundColor $color
    if ($Details) { 
        Write-Host "       Details: $Details" -ForegroundColor Gray
    }
    
    $testResults += @{
        Name = $TestName
        Passed = $Passed
        Details = $Details
        Time = Get-Date
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    $exists = Test-Path $Path
    Write-TestResult "File exists: $Description" $exists "Path: $Path"
    return $exists
}

function Test-FolderExists {
    param([string]$Path, [string]$Description)
    $exists = Test-Path $Path -PathType Container
    Write-TestResult "Folder exists: $Description" $exists "Path: $Path"
    return $exists
}

# ============================================================================
# Main Test Suite
# ============================================================================

Write-Host ""
Write-Host "??????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "?  Clean Architecture API Template - GitHub Test     ?" -ForegroundColor Green
Write-Host "?  Complete End-to-End Validation                   ?" -ForegroundColor Green
Write-Host "??????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""
Write-Host "Repository: $RepoUrl" -ForegroundColor White
Write-Host "Test Base:  $TestBase" -ForegroundColor White
Write-Host "Started:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# Phase 1: Clone Repository
# ============================================================================

Write-Header "PHASE 1: REPOSITORY CLONE"

try {
    # Create test directory
    Write-Host "Creating test directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $TestBase -Force -ErrorAction Stop | Out-Null
    Write-TestResult "Test directory created" $true
    
    # Remove existing clone if present
    if (Test-Path "$TestBase\ApiTemplate") {
        Write-Host "Removing existing clone..." -ForegroundColor Yellow
        Remove-Item -Path "$TestBase\ApiTemplate" -Recurse -Force -ErrorAction Stop
        Write-TestResult "Old clone removed" $true
    }
    
    # Clone repository
    Write-Host "Cloning repository..." -ForegroundColor Yellow
    Push-Location $TestBase
    $cloneOutput = git clone $RepoUrl 2>&1
    $cloneSuccess = $LASTEXITCODE -eq 0
    Write-TestResult "Repository cloned" $cloneSuccess
    
    if (-not $cloneSuccess) {
        Write-Host "Clone output: $cloneOutput" -ForegroundColor Red
        exit 1
    }
    
    # Navigate to cloned directory
    cd ApiTemplate
    $pwd = Get-Location
    Write-Host "Current directory: $pwd" -ForegroundColor Gray
}
catch {
    Write-TestResult "Repository operations" $false "Error: $_"
    exit 1
}

# ============================================================================
# Phase 2: Verify Structure
# ============================================================================

Write-Header "PHASE 2: STRUCTURE VERIFICATION"

try {
    # Check template.json
    Test-FileExists ".\.template.config\template.json" "template.json"
    
    # Check documentation
    $docFiles = @("README.md", "START_HERE.md", "QUICKSTART.md", "IMPLEMENTATION.md", "CONTRIBUTING.md")
    foreach ($doc in $docFiles) {
        Test-FileExists ".\$doc" "Documentation: $doc"
    }
    
    # Check source folders
    $srcFolders = @("Core", "Application", "Services", "Infrastructure", "Startup")
    foreach ($folder in $srcFolders) {
        Test-FolderExists ".\src\$folder" "Source: $folder"
    }
}
catch {
    Write-TestResult "Structure verification" $false "Error: $_"
}

# ============================================================================
# Phase 3: Build & Installation
# ============================================================================

Write-Header "PHASE 3: BUILD AND INSTALLATION"

try {
    # Build template
    Write-Host "Building template..." -ForegroundColor Yellow
    $buildOutput = dotnet build 2>&1
    $buildSuccess = $LASTEXITCODE -eq 0
    Write-TestResult "Template builds" $buildSuccess
    
    if (-not $buildSuccess) {
        Write-Host "Build errors:" -ForegroundColor Red
        $buildOutput | Select-String "error" | Write-Host -ForegroundColor Red
    }
    
    # Uninstall existing
    Write-Host "Removing existing template installation..." -ForegroundColor Yellow
    dotnet new uninstall CleanArchApi 2>&1 | Out-Null
    
    # Install template
    Write-Host "Installing template..." -ForegroundColor Yellow
    $installOutput = dotnet new install . --force 2>&1
    $installSuccess = $LASTEXITCODE -eq 0
    Write-TestResult "Template installs" $installSuccess
    
    # Verify installation
    Write-Host "Verifying installation..." -ForegroundColor Yellow
    $listOutput = dotnet new list 2>&1
    $installed = $listOutput | Select-String "cleanapi"
    Write-TestResult "Template in list" ($installed -ne $null)
}
catch {
    Write-TestResult "Build and install" $false "Error: $_"
}

# ============================================================================
# Phase 4: Generate Test Projects
# ============================================================================

Write-Header "PHASE 4: PROJECT GENERATION"

$generateTests = @(
    @{ 
        Name = "Minimal"
        Dir = "Test_Minimal"
        Params = @()
        Description = "Default configuration (xUnit, no DB)"
    },
    @{ 
        Name = "NUnit"
        Dir = "Test_NUnit"
        Params = @("--testFramework nunit")
        Description = "NUnit test framework"
    },
    @{ 
        Name = "MSTest"
        Dir = "Test_MSTest"
        Params = @("--testFramework mstest")
        Description = "MSTest test framework"
    },
    @{ 
        Name = "NoAPI"
        Dir = "Test_NoAPI"
        Params = @("--useApi false")
        Description = "API-less configuration"
    },
    @{ 
        Name = "SQL Server"
        Dir = "Test_SqlServer"
        Params = @("--databaseEngine sqlserver")
        Description = "SQL Server database engine"
    },
    @{ 
        Name = "PostgreSQL"
        Dir = "Test_Postgres"
        Params = @("--databaseEngine postgres")
        Description = "PostgreSQL database engine"
    },
    @{ 
        Name = "AllFeatures"
        Dir = "Test_AllFeatures"
        Params = @(
            "--testFramework xunit",
            "--databaseEngine sqlserver",
            "--useInboundMessaging true",
            "--useSwagger true",
            "--useHealthChecks true"
        )
        Description = "All features enabled"
    }
)

foreach ($test in $generateTests) {
    try {
        $testDir = "$TestBase\$($test.Dir)"
        
        Write-Host "Generating: $($test.Name)" -ForegroundColor Yellow
        Write-Host "  Description: $($test.Description)" -ForegroundColor Gray
        
        # Build command
        $cmd = "dotnet new cleanapi --orgName TestOrg --name $($test.Dir) --output `"$testDir`""
        foreach ($param in $test.Params) {
            $cmd += " $param"
        }
        
        # Generate
        $genOutput = Invoke-Expression $cmd 2>&1
        
        # Verify projects exist (most reliable indicator of successful generation)
        $coreExists = Test-Path "$testDir\src\Core\Core.csproj"
        $appExists = Test-Path "$testDir\src\Application\Application.csproj"
        $startupExists = Test-Path "$testDir\src\Startup\Startup.csproj"
        
        $allExist = $coreExists -and $appExists -and $startupExists
        Write-TestResult "Generate: $($test.Name)" $allExist
    }
    catch {
        Write-TestResult "Generate: $($test.Name)" $false "Error: $_"
    }
}

# ============================================================================
# Phase 5: Build Generated Projects
# ============================================================================

Write-Header "PHASE 5: BUILD VERIFICATION"

foreach ($test in $generateTests) {
    try {
        $testDir = "$TestBase\$($test.Dir)"
        
        Write-Host "Building: $($test.Name)" -ForegroundColor Yellow
        
        Push-Location $testDir
        $buildOutput = dotnet build 2>&1
        $buildSuccess = $LASTEXITCODE -eq 0
        Write-TestResult "Build: $($test.Name)" $buildSuccess
        Pop-Location
    }
    catch {
        Write-TestResult "Build: $($test.Name)" $false "Error: $_"
        Pop-Location
    }
}

# ============================================================================
# Phase 6: Validation
# ============================================================================

Write-Header "PHASE 6: VALIDATION"

try {
    # Check namespace substitution
    $file = Get-Content "$TestBase\Test_Minimal\src\Core\Placeholder.cs" -ErrorAction SilentlyContinue
    $hasNamespace = $file | Select-String "namespace.*TestOrg"
    Write-TestResult "Namespace substitution" ($hasNamespace -ne $null)
    
    # Check project references
    $appProj = Get-Content "$TestBase\Test_Minimal\src\Application\Application.csproj"
    $hasReference = $appProj | Select-String "Core.csproj"
    Write-TestResult "Project references" ($hasReference -ne $null)
}
catch {
    Write-TestResult "Validation" $false "Error: $_"
}

# ============================================================================
# Summary
# ============================================================================

Write-Header "TEST SUMMARY"

$passed = ($testResults | Where-Object { $_.Passed }).Count
$failed = ($testResults | Where-Object { !$_.Passed }).Count
$total = $testResults.Count
$passRate = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 1) } else { 0 }

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "Total Tests:     $total" -ForegroundColor White
Write-Host "Passed:          $passed" -ForegroundColor Green
Write-Host "Failed:          $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate:       $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Duration:        $($duration.TotalSeconds) seconds" -ForegroundColor Gray
Write-Host "Started:         $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

if ($failed -eq 0) {
    Write-Host "?? ALL TESTS PASSED!" -ForegroundColor Green
} elseif ($passed -gt 0) {
    Write-Host "??  $failed test(s) failed - Review details above" -ForegroundColor Yellow
} else {
    Write-Host "? ALL TESTS FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "Generated projects location: $TestBase" -ForegroundColor Cyan
Write-Host ""

# Clean up
Pop-Location

exit $(if ($failed -eq 0) { 0 } else { 1 })

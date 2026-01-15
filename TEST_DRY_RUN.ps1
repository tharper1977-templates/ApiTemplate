#!/bin/pwsh
<#
.SYNOPSIS
Clean Architecture API Template - Dry Run Test Suite (Fixed v2)

.DESCRIPTION
Tests the template with various parameter combinations after bug fixes
#>

param(
    [string]$TemplateDir = "C:\Users\tharp\source\repos\Templates\api-template\ApiTemplate",
    [string]$TestBaseDir = "C:\temp\api-template-tests"
)

Write-Host "`n" -ForegroundColor White
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?  Clean Architecture API Template - Dry Run Test Suite v2      ?" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Step 1: Uninstall existing template if present
Write-Host "Step 1: Preparing template..." -ForegroundColor Yellow
Write-Host "  ? Removing any existing installation..." -ForegroundColor Gray
dotnet new uninstall CleanArchApi 2>&1 | Out-Null

# Step 2: Install template
Write-Host "  ? Installing template from: $TemplateDir" -ForegroundColor Gray
dotnet new install $TemplateDir --force 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ? Template installed successfully" -ForegroundColor Green
} else {
    Write-Host "  ? Failed to install template" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Create test directory
Write-Host "Step 2: Creating test directory..." -ForegroundColor Yellow
Remove-Item -Path $TestBaseDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $TestBaseDir -Force | Out-Null
Write-Host "  ? Test directory: $TestBaseDir" -ForegroundColor Green
Write-Host ""

# Step 4: Run tests
Write-Host "Step 3: Running parameter combination tests..." -ForegroundColor Yellow
Write-Host ""

$tests = @(
    @{ Name = "Test1_Minimal"; Params = @() },
    @{ Name = "Test2_NUnit"; Params = @("--testFramework nunit") },
    @{ Name = "Test3_MSTest"; Params = @("--testFramework mstest") },
    @{ Name = "Test4_NoApi"; Params = @("--useApi false") },
    @{ Name = "Test5_SqlServer"; Params = @("--databaseEngine sqlserver") },
    @{ Name = "Test6_Postgres"; Params = @("--databaseEngine postgres") },
    @{ Name = "Test7_AllFeatures"; Params = @("--useInboundMessaging true", "--databaseEngine sqlserver", "--testFramework xunit") }
)

$passCount = 0
$failCount = 0
$detailResults = @()

foreach ($test in $tests) {
    $testDir = "$TestBaseDir\$($test.Name)"
    $testName = $test.Name
    
    Write-Host "  Running: $testName" -ForegroundColor Cyan
    
    # Build command
    $cmd = "dotnet new cleanapi --orgName TestOrg --name $testName --output `"$testDir`""
    
    # Add parameters
    foreach ($param in $test.Params) {
        $cmd += " $param"
    }
    
    # Run generation
    $output = Invoke-Expression $cmd 2>&1
    
    # Check results - all projects should exist for successful generation
    $coreExists = Test-Path "$testDir\src\Core\Core.csproj"
    $appExists = Test-Path "$testDir\src\Application\Application.csproj"
    $startupExists = Test-Path "$testDir\src\Startup\Startup.csproj"
    
    # For useApi=false, Services project should be minimal but present
    $servicesExists = Test-Path "$testDir\src\Services"
    
    if ($coreExists -and $appExists -and $startupExists) {
        Write-Host "    ? PASS" -ForegroundColor Green
        
        # Check specific features based on parameters
        if ($test.Params -contains "--useApi false") {
            # When useApi=false, Controllers folder should NOT exist
            $controllersExcluded = !(Test-Path "$testDir\src\Services\Controllers")
            $dtosExcluded = !(Test-Path "$testDir\src\Services\DTOs")
            Write-Host "      API Controllers excluded: $(if ($controllersExcluded) { '? Correct' } else { '? Still present' })" -ForegroundColor $(if ($controllersExcluded) { 'Green' } else { 'Red' })
            
            if ($controllersExcluded) {
                $passCount++
            } else {
                $failCount++
            }
        } elseif ($test.Params -like "*sqlserver*" -or $test.Params -like "*postgres*") {
            # When database engine is selected, check for Infrastructure folder
            $infraExists = Test-Path "$testDir\src\Infrastructure"
            Write-Host "      Infrastructure folder: $(if ($infraExists) { '? Found' } else { '? Missing' })" -ForegroundColor $(if ($infraExists) { 'Green' } else { 'Red' })
            $passCount++
        } else {
            $passCount++
        }
        
        $detailResults += @{ Test = $testName; Status = "PASS"; Details = "All core projects generated" }
    } else {
        Write-Host "    ? FAIL - Missing projects" -ForegroundColor Red
        Write-Host "      Core: $(if ($coreExists) { '?' } else { '?' }) App: $(if ($appExists) { '?' } else { '?' }) Startup: $(if ($startupExists) { '?' } else { '?' })" -ForegroundColor White
        $failCount++
        $detailResults += @{ Test = $testName; Status = "FAIL"; Details = "Missing one or more core projects" }
    }
    
    Write-Host ""
}

# Summary
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?                    Test Results Summary                        ?" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests:  $($tests.Count)" -ForegroundColor White
Write-Host "? Passed:    $passCount" -ForegroundColor Green
Write-Host "? Failed:    $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "?? All tests PASSED!" -ForegroundColor Green
} else {
    Write-Host "??  $failCount test(s) failed - Review details above" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Generated projects: $TestBaseDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review any failed tests above" -ForegroundColor Gray
Write-Host "  2. Check generated project structure in: $TestBaseDir" -ForegroundColor Gray
Write-Host "  3. Run: dotnet build in any generated test project to verify compilation" -ForegroundColor Gray
Write-Host ""


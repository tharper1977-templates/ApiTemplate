# GitHub Repository Test Plan
## Clean Architecture API Service Template

**Purpose:** Validate the template works correctly when cloned from GitHub and tested end-to-end.

**Scope:** From GitHub clone ? Template installation ? Project generation ? Build verification

---

## Pre-Test Requirements

### Environment Setup
- [ ] Windows 10 or later (or equivalent)
- [ ] PowerShell 5.1+ installed
- [ ] .NET 10 SDK installed (`dotnet --version` to verify)
- [ ] Git installed and configured
- [ ] Visual Studio Code or Visual Studio (recommended)
- [ ] 2GB free disk space minimum

### Verification Commands
```powershell
# Verify .NET 10 is installed
dotnet --version

# Verify PowerShell version
$PSVersionTable.PSVersion

# Verify Git is installed
git --version
```

---

## Test Execution Steps

### Phase 1: Repository Cloning & Setup

#### Test 1.1: Clone Repository
```powershell
# Create test directory
$testBase = "C:\temp\github-template-test"
New-Item -ItemType Directory -Path $testBase -Force

# Navigate to test directory
cd $testBase

# Clone repository
git clone https://github.com/tharper1977-templates/ApiTemplate.git

# Navigate into cloned directory
cd ApiTemplate
```

**Expected Result:** ? Repository cloned successfully to `ApiTemplate` folder

**Verification Checklist:**
- [ ] `.template.config` folder exists
- [ ] `README.md` file exists
- [ ] `CONTRIBUTING.md` file exists
- [ ] `src` folder contains 5 project folders (Core, Application, Services, Infrastructure, Startup)
- [ ] `test` folder contains test projects

#### Test 1.2: Verify Directory Structure
```powershell
# List key directories
Get-ChildItem -Path . -Directory | Select-Object Name

# Verify template.json exists
Test-Path ".\.template.config\template.json"

# Verify documentation exists
Test-Path ".\README.md"
Test-Path ".\START_HERE.md"
Test-Path ".\QUICKSTART.md"
Test-Path ".\IMPLEMENTATION.md"
Test-Path ".\CONTRIBUTING.md"
```

**Expected Result:** ? All expected files and folders present

---

### Phase 2: Build & Installation

#### Test 2.1: Verify Template Syntax
```powershell
# Build the template to ensure no errors
dotnet build

# Check for any compilation errors
# Expected: Build successful message
```

**Expected Result:** ? Build successful with 0 errors, 0 warnings

**Verification Checklist:**
- [ ] No CS errors in output
- [ ] No build warnings
- [ ] "Build succeeded" message shown

#### Test 2.2: Install Template Locally
```powershell
# Remove any existing installation
dotnet new uninstall CleanArchApi 2>$null

# Install from local path
dotnet new install . --force

# Verify installation
dotnet new list | Select-String cleanapi
```

**Expected Result:** ? Template installed successfully

**Verification Output:** Should show template details:
```
CleanArchApi           dotnet new cleanapi
```

---

### Phase 3: Template Generation Tests

#### Test 3.1: Minimal Configuration
```powershell
$testDir = "$testBase\TestMinimal"
dotnet new cleanapi --orgName TestOrg --name MinimalTest --output $testDir
```

**Validation Script:**
```powershell
# Check all core projects exist
$coreExists = Test-Path "$testDir\src\Core\Core.csproj"
$appExists = Test-Path "$testDir\src\Application\Application.csproj"
$servicesExists = Test-Path "$testDir\src\Services\Services.csproj"
$infraExists = Test-Path "$testDir\src\Infrastructure\Infrastructure.csproj"
$startupExists = Test-Path "$testDir\src\Startup\Startup.csproj"

Write-Host "Core: $coreExists, App: $appExists, Services: $servicesExists, Infra: $infraExists, Startup: $startupExists"

# Check test projects
$unitExists = Test-Path "$testDir\test\Unit\Unit.csproj"
$integrationExists = Test-Path "$testDir\test\Integration\Integration.csproj"

Write-Host "Unit Tests: $unitExists, Integration Tests: $integrationExists"
```

**Expected Result:** ? All 7 projects generated (5 source + 2 test)

**Verification Checklist:**
- [ ] Core.csproj exists
- [ ] Application.csproj exists
- [ ] Services.csproj exists
- [ ] Infrastructure.csproj exists
- [ ] Startup.csproj exists
- [ ] Unit.csproj exists
- [ ] Integration.csproj exists

#### Test 3.2: NUnit Test Framework
```powershell
$testDir = "$testBase\TestNUnit"
dotnet new cleanapi --orgName TestOrg --name NUnitTest --output $testDir --testFramework nunit
```

**Validation:**
```powershell
# Check test project contains NUnit references
$unitProj = Get-Content "$testDir\test\Unit\Unit.csproj" | Select-String "NUnit"
$integrationProj = Get-Content "$testDir\test\Integration\Integration.csproj" | Select-String "NUnit"

Write-Host "Unit has NUnit: $($unitProj -ne $null)"
Write-Host "Integration has NUnit: $($integrationProj -ne $null)"
```

**Expected Result:** ? NUnit packages referenced in test projects

#### Test 3.3: MSTest Test Framework
```powershell
$testDir = "$testBase\TestMSTest"
dotnet new cleanapi --orgName TestOrg --name MSTestTest --output $testDir --testFramework mstest
```

**Validation:**
```powershell
# Check for MSTest packages
$unitProj = Get-Content "$testDir\test\Unit\Unit.csproj" | Select-String "MSTest"
Write-Host "Unit has MSTest: $($unitProj -ne $null)"
```

**Expected Result:** ? MSTest packages configured

#### Test 3.4: SQL Server Database Engine
```powershell
$testDir = "$testBase\TestSqlServer"
dotnet new cleanapi --orgName TestOrg --name SqlServerTest --output $testDir --databaseEngine sqlserver
```

**Validation:**
```powershell
# Check Infrastructure folder structure
$reposExists = Test-Path "$testDir\src\Infrastructure\Repositories"
$clientsExists = Test-Path "$testDir\src\Infrastructure\Clients"

Write-Host "Repositories folder: $reposExists"
Write-Host "Clients folder: $clientsExists"

# Check for EF Core SQL Server package
$infraProj = Get-Content "$testDir\src\Infrastructure\Infrastructure.csproj" | Select-String "SqlServer"
Write-Host "Has SQL Server package: $($infraProj -ne $null)"
```

**Expected Result:** ? Infrastructure configured with SQL Server support

#### Test 3.5: PostgreSQL Database Engine
```powershell
$testDir = "$testBase\TestPostgres"
dotnet new cleanapi --orgName TestOrg --name PostgresTest --output $testDir --databaseEngine postgres
```

**Validation:**
```powershell
# Check for Npgsql package
$infraProj = Get-Content "$testDir\src\Infrastructure\Infrastructure.csproj" | Select-String "Npgsql"
Write-Host "Has Npgsql package: $($infraProj -ne $null)"
```

**Expected Result:** ? Infrastructure configured with PostgreSQL support

#### Test 3.6: API-Less Mode (useApi=false)
```powershell
$testDir = "$testBase\TestNoApi"
dotnet new cleanapi --orgName TestOrg --name NoApiTest --output $testDir --useApi false
```

**Validation:**
```powershell
# Check that controllers are excluded
$controllersExists = Test-Path "$testDir\src\Services\Controllers"
# But Services project should still exist
$servicesExists = Test-Path "$testDir\src\Services"

Write-Host "Services exists (should be true): $servicesExists"
Write-Host "Controllers excluded (should be false): $controllersExists"
```

**Expected Result:** ? Services project exists but Controllers excluded

#### Test 3.7: Messaging Support (useInboundMessaging=true)
```powershell
$testDir = "$testBase\TestMessaging"
dotnet new cleanapi --orgName TestOrg --name MessagingTest --output $testDir --useInboundMessaging true
```

**Validation:**
```powershell
# Check for messaging folder
$messagingExists = Test-Path "$testDir\src\Services\Messaging"
Write-Host "Messaging folder exists: $messagingExists"
```

**Expected Result:** ? Messaging folder exists with consumer templates

---

### Phase 4: Build Verification

#### Test 4.1: Build Minimal Project
```powershell
cd "$testBase\TestMinimal"
dotnet build
```

**Expected Result:** ? Build successful, 0 errors, 0 warnings

**Log Check:**
```powershell
# Should see "Build succeeded"
# Should see no error CS codes
# Should see no warning messages
```

#### Test 4.2: Build with SQL Server
```powershell
cd "$testBase\TestSqlServer"
dotnet build
```

**Expected Result:** ? Build successful despite optional database components

#### Test 4.3: Restore & Build in Subdirectory
```powershell
cd "$testBase\TestMinimal\src"
dotnet restore
dotnet build
```

**Expected Result:** ? Projects can be built from subdirectory

---

### Phase 5: Namespace & Configuration Verification

#### Test 5.1: Check Namespace Substitution
```powershell
# Open a C# file and verify namespace replacement
$file = Get-Content "$testBase\TestMinimal\src\Core\Class1.cs"
$hasCorrectNamespace = $file | Select-String "namespace TestOrg.testproject"

Write-Host "Namespace correctly substituted: $($hasCorrectNamespace -ne $null)"
```

**Expected Result:** ? Namespace shows `TestOrg.testproject` (or normalized form)

#### Test 5.2: Check Project References
```powershell
# Verify Application references Core
$appProj = Get-Content "$testBase\TestMinimal\src\Application\Application.csproj"
$coreRef = $appProj | Select-String "Core.csproj"

Write-Host "Application references Core: $($coreRef -ne $null)"
```

**Expected Result:** ? All project references correctly configured

---

### Phase 6: Documentation Verification

#### Test 6.1: Verify Documentation Files Exist
```powershell
$docFiles = @(
    "README.md",
    "START_HERE.md",
    "QUICKSTART.md",
    "IMPLEMENTATION.md",
    "CONTRIBUTING.md",
    "INDEX.md"
)

foreach ($doc in $docFiles) {
    $exists = Test-Path ".\$doc"
    Write-Host "$doc exists: $exists"
}
```

**Expected Result:** ? All 6 core documentation files present

#### Test 6.2: Check Documentation Content
```powershell
# README.md should contain "Clean Architecture"
$readme = Get-Content ".\README.md" | Select-String "Clean Architecture"
Write-Host "README has content: $($readme -ne $null)"

# QUICKSTART.md should contain installation steps
$quickstart = Get-Content ".\QUICKSTART.md" | Select-String "Installation"
Write-Host "QUICKSTART has installation: $($quickstart -ne $null)"
```

**Expected Result:** ? Documentation contains expected content

---

### Phase 7: Parameter Combination Tests

#### Test 7.1: Multiple Parameters
```powershell
$testDir = "$testBase\TestComplex"
dotnet new cleanapi `
    --orgName MyCompany `
    --name ComplexProject `
    --output $testDir `
    --testFramework nunit `
    --databaseEngine sqlserver `
    --useInboundMessaging true `
    --useSwagger true `
    --useHealthChecks true
```

**Validation:**
```powershell
# All 7 projects should exist
$projects = @(
    "$testDir\src\Core\Core.csproj",
    "$testDir\src\Application\Application.csproj",
    "$testDir\src\Services\Services.csproj",
    "$testDir\src\Infrastructure\Infrastructure.csproj",
    "$testDir\src\Startup\Startup.csproj",
    "$testDir\test\Unit\Unit.csproj",
    "$testDir\test\Integration\Integration.csproj"
)

foreach ($proj in $projects) {
    $exists = Test-Path $proj
    Write-Host "$proj : $exists"
}
```

**Expected Result:** ? All projects generated with combined parameters

#### Test 7.2: Build Complex Project
```powershell
cd "$testBase\TestComplex"
dotnet build
```

**Expected Result:** ? Complex project builds successfully

---

## Test Execution Script

Create a PowerShell script to run all tests automatically:

```powershell
# save as: test-github-template.ps1

param(
    [string]$RepoUrl = "https://github.com/tharper1977-templates/ApiTemplate.git",
    [string]$TestBase = "C:\temp\github-template-test"
)

$testResults = @()

function Test-Result {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details
    )
    
    $status = if ($Passed) { "? PASS" } else { "? FAIL" }
    Write-Host "$status - $TestName"
    if ($Details) { Write-Host "  Details: $Details" }
    
    $testResults += @{
        Name = $TestName
        Passed = $Passed
        Details = $Details
    }
}

Write-Host ""
Write-Host "???????????????????????????????????????????????"
Write-Host "GitHub Template Test Suite"
Write-Host "???????????????????????????????????????????????"
Write-Host ""

# Phase 1: Clone
Write-Host "Phase 1: Repository Clone"
try {
    New-Item -ItemType Directory -Path $TestBase -Force | Out-Null
    Push-Location $TestBase
    
    if (Test-Path "ApiTemplate") {
        Remove-Item -Path "ApiTemplate" -Recurse -Force
    }
    
    git clone $RepoUrl 2>&1 | Out-Null
    cd ApiTemplate
    
    $cloned = Test-Path ".\.template.config\template.json"
    Test-Result "Repository Cloned" $cloned
}
catch {
    Test-Result "Repository Cloned" $false "Error: $_"
}

# Phase 2: Build
Write-Host ""
Write-Host "Phase 2: Build & Installation"
try {
    $buildOutput = dotnet build 2>&1
    $buildSuccess = $LASTEXITCODE -eq 0
    Test-Result "Build Template" $buildSuccess
    
    dotnet new uninstall CleanArchApi 2>&1 | Out-Null
    dotnet new install . --force 2>&1 | Out-Null
    $installed = dotnet new list | Select-String "cleanapi"
    Test-Result "Install Template" ($installed -ne $null)
}
catch {
    Test-Result "Build & Install" $false "Error: $_"
}

# Phase 3: Generate Projects
Write-Host ""
Write-Host "Phase 3: Template Generation"

$generateTests = @(
    @{ Name = "Minimal"; Dir = "TestMinimal"; Params = @() },
    @{ Name = "NUnit"; Dir = "TestNUnit"; Params = @("--testFramework nunit") },
    @{ Name = "SQL Server"; Dir = "TestSqlServer"; Params = @("--databaseEngine sqlserver") }
)

foreach ($test in $generateTests) {
    try {
        $testDir = "$TestBase\$($test.Dir)"
        $cmd = "dotnet new cleanapi --orgName TestOrg --name $($test.Dir) --output `"$testDir`""
        foreach ($param in $test.Params) {
            $cmd += " $param"
        }
        
        Invoke-Expression $cmd 2>&1 | Out-Null
        
        $coreExists = Test-Path "$testDir\src\Core\Core.csproj"
        $appExists = Test-Path "$testDir\src\Application\Application.csproj"
        $generated = $coreExists -and $appExists
        
        Test-Result "Generate: $($test.Name)" $generated
    }
    catch {
        Test-Result "Generate: $($test.Name)" $false "Error: $_"
    }
}

# Phase 4: Build Generated Projects
Write-Host ""
Write-Host "Phase 4: Build Verification"

foreach ($test in $generateTests) {
    try {
        Push-Location "$TestBase\$($test.Dir)"
        $buildOut = dotnet build 2>&1
        $buildOk = $LASTEXITCODE -eq 0
        Test-Result "Build: $($test.Name)" $buildOk
        Pop-Location
    }
    catch {
        Test-Result "Build: $($test.Name)" $false "Error: $_"
        Pop-Location
    }
}

# Summary
Write-Host ""
Write-Host "???????????????????????????????????????????????"
Write-Host "Test Summary"
Write-Host "???????????????????????????????????????????????"

$passed = ($testResults | Where-Object { $_.Passed }).Count
$failed = ($testResults | Where-Object { !$_.Passed }).Count
$total = $testResults.Count

Write-Host "Total: $total"
Write-Host "Passed: $passed"
Write-Host "Failed: $failed"
Write-Host ""

if ($failed -eq 0) {
    Write-Host "?? All tests PASSED!" -ForegroundColor Green
} else {
    Write-Host "?? Some tests failed" -ForegroundColor Yellow
}

Pop-Location
```

---

## Manual Test Checklist

Complete this checklist as you run tests:

### Phase 1: Clone & Setup
- [ ] Repository cloned successfully
- [ ] All expected folders present
- [ ] .template.config/template.json valid
- [ ] Documentation files present

### Phase 2: Build & Install
- [ ] dotnet build succeeds (0 errors, 0 warnings)
- [ ] Template installs without errors
- [ ] Template appears in `dotnet new list`

### Phase 3: Generation Tests
- [ ] Minimal project generates (all 7 projects)
- [ ] NUnit framework generates correct test projects
- [ ] MSTest framework generates correct test projects
- [ ] SQL Server engine includes EF Core packages
- [ ] PostgreSQL engine includes Npgsql
- [ ] API-less mode excludes controllers
- [ ] Messaging support generates consumers

### Phase 4: Build Tests
- [ ] Minimal project builds successfully
- [ ] SQL Server project builds
- [ ] PostgreSQL project builds
- [ ] Complex (multi-parameter) project builds

### Phase 5: Verification Tests
- [ ] Namespaces correctly substituted
- [ ] Project references valid
- [ ] Documentation files present and valid
- [ ] No orphaned files or folders

### Phase 6: Documentation Validation
- [ ] README.md has content
- [ ] START_HERE.md is readable
- [ ] QUICKSTART.md has setup steps
- [ ] IMPLEMENTATION.md is comprehensive
- [ ] CONTRIBUTING.md has guidelines
- [ ] INDEX.md provides navigation

---

## Success Criteria

? **Template is validated when:**
- [x] Repository clones without errors
- [x] Template builds with 0 errors, 0 warnings
- [x] Template installs successfully
- [x] All 7 test scenarios generate projects
- [x] All generated projects build successfully
- [x] Namespace substitution works correctly
- [x] Project references are valid
- [x] Documentation is complete and accessible
- [x] No warnings or errors during generation
- [x] Parameter combinations work correctly

---

## Troubleshooting

### Template Installation Fails
```powershell
# Clear template cache
dotnet new uninstall CleanArchApi
dotnet new uninstall "C:\path\to\template"

# Reinstall
dotnet new install "C:\path\to\template" --force
```

### Build Errors
```powershell
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build
```

### Git Clone Issues
```powershell
# Verify Git is working
git --version

# Try cloning with verbose output
git clone --verbose https://github.com/tharper1977-templates/ApiTemplate.git
```

### PowerShell Execution Policy
```powershell
# If scripts won't run, check execution policy
Get-ExecutionPolicy

# Allow script execution (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Report Template

Use this template to document your test results:

```markdown
# Template Test Report

**Date:** [Date]
**Tester:** [Your Name]
**Repository:** https://github.com/tharper1977-templates/ApiTemplate

## Environment
- .NET Version: [dotnet --version]
- PowerShell Version: [PSVersionTable.PSVersion]
- OS: [Windows Version]

## Test Results

### Phase 1: Clone & Setup
- Repository Clone: ?/?
- Directory Structure: ?/?
- Template.json Valid: ?/?

### Phase 2: Build & Install
- Build Successful: ?/?
- Template Installed: ?/?

### Phase 3: Generation
- Minimal: ?/?
- NUnit: ?/?
- MSTest: ?/?
- SQL Server: ?/?
- PostgreSQL: ?/?
- API-less: ?/?
- Messaging: ?/?

### Phase 4: Builds
- Minimal Build: ?/?
- SQL Server Build: ?/?
- PostgreSQL Build: ?/?

## Summary
- Total Tests: [X]
- Passed: [X]
- Failed: [X]
- Pass Rate: [X]%

## Notes
[Any observations or issues]
```

---

**This test plan ensures complete validation of the template from GitHub installation through project generation and build verification.** ?

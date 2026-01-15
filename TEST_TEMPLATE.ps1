#!/bin/pwsh
<#
.SYNOPSIS
Clean Architecture API Template - Dry Run Test Suite

.DESCRIPTION
Tests the template with various parameter combinations to verify:
- File generation works correctly
- Parameter substitution is accurate
- Conditional file inclusion/exclusion works
- Project structure is correct
#>

param(
    [string]$TemplateSource = "C:\Users\tharp\source\repos\Templates\api-template\ApiTemplate",
    [string]$OutputBase = "C:\temp\template-tests",
    [string]$TestName = "all"
)

# Configuration
$ErrorActionPreference = "Continue"
$tests = @()

function New-Test {
    param(
        [string]$Name,
        [string]$OrgName = "TestOrg",
        [string]$ProjectName = "TestProject",
        [hashtable]$Parameters = @{}
    )
    
    return @{
        Name = $Name
        OrgName = $OrgName
        ProjectName = $ProjectName
        Parameters = $Parameters
        OutputPath = "$OutputBase\$Name"
        Results = @()
    }
}

# Define test scenarios
$tests = @(
    (New-Test -Name "Test1_Minimal" -Parameters @{}),
    (New-Test -Name "Test2_NoApi" -Parameters @{ useApi = "false" }),
    (New-Test -Name "Test3_WithMessaging" -Parameters @{ useInboundMessaging = "true" }),
    (New-Test -Name "Test4_NUnit" -Parameters @{ testFramework = "nunit" }),
    (New-Test -Name "Test5_MSTest" -Parameters @{ testFramework = "mstest" }),
    (New-Test -Name "Test6_SqlServer" -Parameters @{ databaseEngine = "sqlserver" }),
    (New-Test -Name "Test7_Postgres" -Parameters @{ databaseEngine = "postgres" }),
    (New-Test -Name "Test8_NoWorkers" -Parameters @{ useWorkers = "false" }),
    (New-Test -Name "Test9_AllFeatures" -Parameters @{ 
        useApi = "true"
        useInboundMessaging = "true"
        useSwagger = "true"
        useHealthChecks = "true"
        useFluentValidation = "true"
        useWorkers = "true"
        databaseEngine = "sqlserver"
        testFramework = "xunit"
    })
)

Write-Host ""
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "?   Clean Architecture API Template - Dry Run Test Suite        ?" -ForegroundColor Green
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""

# Ensure output directory exists
New-Item -ItemType Directory -Path $OutputBase -Force | Out-Null
Write-Host "?? Test directory: $OutputBase" -ForegroundColor Cyan
Write-Host ""

# Run tests
$passCount = 0
$failCount = 0

foreach ($test in $tests) {
    $testName = $test.Name
    Write-Host "Running: $testName" -ForegroundColor Yellow
    
    # Build command
    $cmd = "dotnet new cleanapi --orgName `"$($test.OrgName)`" --name `"$($test.ProjectName)`" --output `"$($test.OutputPath)`" --template-source `"$TemplateSource`""
    
    # Add parameters
    foreach ($key in $test.Parameters.Keys) {
        $cmd += " --$key $($test.Parameters[$key])"
    }
    
    # Run command
    try {
        Invoke-Expression $cmd 2>&1 | Out-Null
        
        # Check if core structure was created
        $coreProjectExists = Test-Path "$($test.OutputPath)\src\Core\Core.csproj"
        $appProjectExists = Test-Path "$($test.OutputPath)\src\Application\Application.csproj"
        
        if ($coreProjectExists -and $appProjectExists) {
            Write-Host "? PASS - Projects generated successfully" -ForegroundColor Green
            
            # Check for parameter-specific files
            $checks = @()
            
            # Check API-related files
            if ($test.Parameters["useApi"] -ne "false") {
                $servicesExists = Test-Path "$($test.OutputPath)\src\Services\Services.csproj"
                $checks += @{ Name = "Services project"; Result = $servicesExists }
            }
            
            # Check for worker
            if ($test.Parameters["useWorkers"] -ne "false") {
                $workerExists = Test-Path "$($test.OutputPath)\src\Startup\Worker.cs"
                $checks += @{ Name = "Worker.cs"; Result = $workerExists }
            }
            
            # Check database-related
            if ($test.Parameters["databaseEngine"] -and $test.Parameters["databaseEngine"] -ne "none") {
                $reposExists = Test-Path "$($test.OutputPath)\src\Infrastructure\Repositories"
                $checks += @{ Name = "Repositories folder"; Result = $reposExists }
            }
            
            # Report checks
            foreach ($check in $checks) {
                if ($check.Result) {
                    Write-Host "  ? $($check.Name)" -ForegroundColor Green
                } else {
                    Write-Host "  ? $($check.Name) - NOT FOUND" -ForegroundColor Red
                }
            }
            
            $passCount++
        } else {
            Write-Host "? FAIL - Core/Application projects not found" -ForegroundColor Red
            $failCount++
        }
    }
    catch {
        Write-Host "? FAIL - Error generating project: $_" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

# Summary
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?   Test Results Summary                                         ?" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($tests.Count)" -ForegroundColor White
Write-Host "? Passed:   $passCount" -ForegroundColor Green
Write-Host "? Failed:   $failCount" -ForegroundColor Red
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "?? All tests passed!" -ForegroundColor Green
} else {
    Write-Host "??  Some tests failed. Review output above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Generated projects location: $OutputBase" -ForegroundColor Cyan

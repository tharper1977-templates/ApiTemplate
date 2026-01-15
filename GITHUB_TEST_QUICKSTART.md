# Quick Reference: GitHub Test Execution

## Option 1: Automated Test (Recommended)

### Quick Start
```powershell
# Download and run the automated test script
.\test-github-template.ps1
```

### Custom Location
```powershell
# Run tests in custom directory
.\test-github-template.ps1 -TestBase "D:\MyTests"
```

### Expected Output
```
??????????????????????????????????????????????????
?  Clean Architecture API Template - GitHub Test ?
??????????????????????????????????????????????????

? PASS - Repository cloned
? PASS - Template builds
? PASS - Template installs
? PASS - Generate: Minimal
? PASS - Generate: NUnit
? PASS - Generate: MSTest
? PASS - Generate: NoAPI
? PASS - Generate: SQL Server
? PASS - Generate: PostgreSQL
? PASS - Generate: AllFeatures
? PASS - Build: Minimal
? PASS - Build: SQL Server
[... more builds ...]

??????????????????????????????????????????????????
? TEST SUMMARY                                   ?
??????????????????????????????????????????????????

Total Tests:     X
Passed:          X
Failed:          0
Pass Rate:       100%

?? ALL TESTS PASSED!
```

---

## Option 2: Manual Testing

### Step 1: Clone Repository
```powershell
git clone https://github.com/tharper1977-templates/ApiTemplate.git
cd ApiTemplate
```

### Step 2: Build & Install
```powershell
# Build
dotnet build

# Install template
dotnet new install .

# Verify
dotnet new list | Select-String cleanapi
```

### Step 3: Generate Test Project
```powershell
# Basic project
dotnet new cleanapi --orgName MyOrg --name MyApiTest

# Build generated project
cd MyApiTest
dotnet build
```

### Step 4: Test Parameter Combinations
```powershell
# Test frameworks
dotnet new cleanapi --orgName MyOrg --name TestNUnit --testFramework nunit
dotnet new cleanapi --orgName MyOrg --name TestMSTest --testFramework mstest

# Database engines
dotnet new cleanapi --orgName MyOrg --name TestSql --databaseEngine sqlserver
dotnet new cleanapi --orgName MyOrg --name TestPg --databaseEngine postgres

# API-less mode
dotnet new cleanapi --orgName MyOrg --name TestNoApi --useApi false

# All features
dotnet new cleanapi --orgName MyOrg --name TestAll `
  --testFramework nunit `
  --databaseEngine sqlserver `
  --useInboundMessaging true
```

---

## What Gets Tested

### Automated Test Coverage
? Repository clone from GitHub  
? Directory structure validation  
? Template build (0 errors, 0 warnings)  
? Template installation  
? 7 project generation scenarios  
? 7 build verifications  
? Namespace substitution  
? Project references  

### Test Scenarios
1. **Minimal** - Default everything
2. **NUnit** - Alternative test framework
3. **MSTest** - Third test framework
4. **NoAPI** - useApi=false parameter
5. **SQL Server** - SQL Server database
6. **PostgreSQL** - PostgreSQL database
7. **AllFeatures** - Multiple parameters combined

---

## Success Criteria

All of these must pass:

```
? Repository clones without errors
? Template builds with 0 errors, 0 warnings
? Template installs successfully
? All 7 generation tests pass
? All 7 build tests pass
? Namespaces correctly substituted
? Project references valid
? Pass rate = 100%
```

---

## Troubleshooting

### Script Won't Run
```powershell
# Check execution policy
Get-ExecutionPolicy

# Allow scripts (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Clone Fails
```powershell
# Verify Git
git --version

# Try again with verbose
git clone --verbose https://github.com/tharper1977-templates/ApiTemplate.git
```

### Template Won't Install
```powershell
# Clear cache
dotnet new uninstall CleanArchApi

# Reinstall
dotnet new install . --force
```

### Build Fails
```powershell
# Clean and restore
cd YourGeneratedProject
dotnet clean
dotnet restore
dotnet build
```

---

## File Locations

**After clone:**
```
C:\temp\github-template-test\ApiTemplate\
??? src\
??? test\
??? .template.config\
??? README.md
??? START_HERE.md
??? ...
```

**After running tests:**
```
C:\temp\github-template-test\
??? ApiTemplate\           (cloned template)
??? Test_Minimal\          (generated project)
??? Test_NUnit\
??? Test_MSTest\
??? Test_NoAPI\
??? Test_SqlServer\
??? Test_Postgres\
??? Test_AllFeatures\
```

---

## Report Your Results

Document your test results using this format:

```markdown
# GitHub Template Test Report

**Date:** [Date]  
**Tester:** [Name]  
**Environment:** Windows 10, PowerShell 7, .NET 10

## Results
- Total Tests: [X]
- Passed: [X]
- Failed: [X]
- Pass Rate: [X]%

## Status: ? PASSED / ?? PARTIAL / ? FAILED

## Notes
[Any observations or issues]
```

---

## Verifying Generated Projects

### Check Structure
```powershell
# List generated project structure
cd MyApiTest
Get-ChildItem -Recurse -Directory src | Select-Object FullName
```

### Check Namespaces
```powershell
# Verify namespace substitution
Select-String "namespace" src\Core\*.cs
```

### Check Build Output
```powershell
# Build with detailed output
dotnet build --verbosity detailed
```

### Verify All Projects Reference Correctly
```powershell
# Show project references
dotnet sln MyApiTest.sln list
```

---

## Next Steps After Testing

? If all tests pass:
- Template is ready for production use
- Can be published to NuGet
- Can be shared with team
- Can be used to generate projects

?? If some tests fail:
- Review GITHUB_TEST_PLAN.md for detailed steps
- Check test output for specific errors
- Refer to troubleshooting section above
- Open GitHub issue if problem persists

---

**For detailed test plan, see: GITHUB_TEST_PLAN.md**

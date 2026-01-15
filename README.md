# Clean Architecture API Service Template

A comprehensive .NET 10 template for building scalable API services using clean/onion architecture with strict separation of concerns.

## Overview

This template enforces a disciplined, layered architecture that prevents business logic from leaking into infrastructure or service layers. All scaffolded code includes `NotImplementedException` placeholders, ensuring you maintain control over implementation while following architectural patterns from day one.

## Architecture Layers

- **Core**: Domain entities, business exceptions, constants, and enumerations
- **Application**: Orchestrators, service interfaces, specifications, and validation rules
- **Services**: API controllers, middleware, request/response DTOs, and inbound messaging
- **Infrastructure**: Repository implementations, external API clients, outbound messaging, and database contexts
- **Startup**: Application entry point with dependency injection orchestration

## Key Features

- ✓ Strict onion/adapter architecture enforcement
- ✓ No business logic in Infrastructure or Services layers
- ✓ Middleware-first request handling with proper separation of concerns
- ✓ Generic orchestrators based on Core entities
- ✓ Specifications for query and validation logic
- ✓ DTOs properly segregated by project responsibility
- ✓ NotImplementedException placeholders for all scaffolded methods
- ✓ Parameterized database support (SQL Server, PostgreSQL, Cassandra)
- ✓ Flexible test framework selection (xUnit, NUnit, MSTest)
- ✓ External API client organization by domain
- ✓ GOLD database read-only support (no code-first migrations)
- ✓ Conditional feature generation (API, messaging, workers, validation)

## Installation

### Install Template Locally

```bash
# Install from local path
dotnet new install C:\path\to\ApiTemplate

# Or from GitHub (when published)
dotnet new install https://github.com/tharper1977-templates/ApiTemplate.git
```

### Verify Installation

```bash
# List all installed templates
dotnet new list

# Search for your template
dotnet new list | findstr cleanapi
```

### Test Template Without Installing

To test the template without installing it globally, create a test project directly:

```bash
# Create a test project from local template path
dotnet new cleanapi \
  --orgName TestOrg \
  --name TestProject \
  --template-source C:\path\to\ApiTemplate

# Review the generated structure, then delete if satisfied
# No need to uninstall
```

### Reinstall or Update Template

```bash
# Reinstall with --force flag
dotnet new install C:\path\to\ApiTemplate --force

# Uninstall if needed
dotnet new uninstall ApiTemplate
```

## Usage

### Basic Setup

```bash
dotnet new cleanapi --orgName MyOrg --name MyApiService
```

### With Optional Features

```bash
dotnet new cleanapi \
  --orgName MyOrg \
  --name MyApiService \
  --testFramework nunit \
  --databaseEngine sqlserver \
  --useSwagger true \
  --useHealthChecks true \
  --useFluentValidation true
```

### With External Dependencies

```bash
dotnet new cleanapi \
  --orgName MyOrg \
  --name MyApiService \
  --externalApiClients "Payment,Notification,User" \
  --externalDatabases "Audit,Analytics" \
  --databaseEngine postgres
```

## Template Parameters

### Required

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--orgName` | Organization name for namespace root | `MyOrg` |

### Optional - Services Layer

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--useApi` | Generate API controllers and middleware | `true` |
| `--useInboundMessaging` | Generate inbound message consumers | `false` |
| `--useSwagger` | Enable Swagger/OpenAPI documentation | `true` |
| `--useHealthChecks` | Enable health checks endpoint | `true` |

### Optional - Application Layer

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--useFluentValidation` | Enable FluentValidation framework | `true` |

### Optional - Infrastructure Layer

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--databaseEngine` | Database technology: `none`, `sqlserver`, `postgres`, `cassandra` | `none` |
| `--externalApiClients` | Comma-separated external API domains | (empty) |
| `--externalDatabases` | Comma-separated external GOLD database names | (empty) |

### Optional - Startup & Testing

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--useWorkers` | Generate background worker services | `true` |
| `--testFramework` | Test framework: `xunit`, `nunit`, `mstest` | `xunit` |

## Project Structure

```
src/
├── Core/
│   ├── Entities/          # Business domain objects
│   ├── Exceptions/        # Domain-level exceptions
│   ├── Constants/         # Business constants
│   └── Enums/             # Business enumerations
│
├── Application/
│   ├── Interfaces/        # Service contracts
│   ├── Orchestration/     # Business orchestrators
│   ├── Specifications/    # Query/validation specs
│   ├── Validators/        # FluentValidation rules
│   └── DependencyInjection/
│
├── Services/
│   ├── Controllers/       # API endpoints
│   ├── Middleware/        # Request processing
│   ├── DTOs/
│   │   ├── Requests/      # Inbound request models
│   │   └── Responses/     # Outbound response models
│   ├── Messaging/
│   │   └── Inbound/       # Message consumers
│   ├── Contexts/          # Service-specific logic
│   └── DependencyInjection/
│
├── Infrastructure/
│   ├── Clients/           # External API clients
│   │   └── DTOs/          # API DTOs (records)
│   ├── Repositories/      # Owned database repos
│   │   ├── EF/            # Entity Framework configs
│   │   └── DbContexts/    # Database contexts
│   ├── ExternalRepositories/  # GOLD database repos
│   ├── Messaging/
│   │   └── Outbound/      # Message publishers
│   ├── Contexts/          # Infrastructure logic
│   └── DependencyInjection/
│
└── Startup/
    ├── Program.cs         # Application entry point
    ├── Worker.cs          # Background worker
    └── appsettings.json   # Configuration

tests/
├── Unit/
│   └── *.Tests.cs         # Unit test fixtures
└── Integration/
    └── *.Tests.cs         # Integration test fixtures
```

## Architecture Principles

### Core Layer
- Contains pure business logic with no infrastructure dependencies
- Entities represent business domain objects
- No attributes beyond data annotations for properties
- Exceptions are domain-specific

### Application Layer
- Defines contracts (interfaces) for all external dependencies
- Interfaces use generics based on Core entities
- Orchestrators coordinate business workflows
- Specifications encapsulate query/validation logic
- FluentValidation rules validate input
- No implementation details—only contracts and logic

### Services Layer
- API controllers remain thin—delegate to orchestrators
- Middleware handles request validation, mapping, and error responses
- DTOs for inbound requests/outbound responses
- Inbound messaging consumers process events
- DI wiring for Services-specific concerns

### Infrastructure Layer
- Implements Application interfaces
- Repositories access data via EF Core or specialized clients
- External API clients organized by domain
- DTOs for external APIs use C# records
- GOLD databases are read-only (never modify with code-first)

### Startup Layer
- Minimal setup—call DI registration from each layer
- Program.cs orchestrates service registration
- Worker.cs implements long-running tasks

## Dependency Injection

**Services Layer** registers:
- Controllers
- Middleware
- API-specific services

**Infrastructure Layer** registers:
- Repository implementations
- External API clients
- Database contexts

**Application Layer** registers:
- Orchestrators
- Validators
- Specifications

**Startup Layer** calls all three, then runs the application.

## Best Practices

1. **Keep Core Pure**: No framework references, no infrastructure concerns
2. **Use Specifications**: Encapsulate complex query/validation logic
3. **Interface-First**: Define contracts in Application before implementing in Infrastructure
4. **DTO Segregation**: Request/Response DTOs in Services; External API DTOs in Infrastructure
5. **Thin Controllers**: Delegate all work to orchestrators
6. **Middleware-First**: Handle cross-cutting concerns (validation, logging, errors) in middleware
7. **NotImplementedException**: Placeholder methods guide implementation order
8. **No Magic Strings**: Use constants defined in Core

## Testing

Both Unit and Integration test projects are generated with your selected test framework:

- **Unit Tests**: Test Core and Application layers (no external dependencies)
- **Integration Tests**: Test full feature flows with infrastructure

All test files include framework-specific global usings for clean test code.

## License

This template is provided as-is for use in building clean architecture .NET applications.

# Clean Architecture API Service Template - Start Here

> A production-ready .NET 10 template for building scalable API services with clean/onion architecture, comprehensive documentation, and extensible design.

## ?? Start Here

**New to this template?** ? Jump to [QUICKSTART.md](QUICKSTART.md) for a 5-minute setup  
**Want complete details?** ? Read [README.md](README.md) for full feature reference  
**Ready to contribute?** ? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines  
**Diving into architecture?** ? Check [IMPLEMENTATION.md](IMPLEMENTATION.md) for deep dive  

## ?? What This Template Provides

??? **Production-Ready Architecture**
- Strict onion/adapter pattern (Core ? Application ? Services/Infrastructure ? Startup)
- SOLID principles throughout
- Enterprise patterns and best practices
- Fully extensible and customizable

?? **Comprehensive Interfaces & Contracts**
- Service contracts defined in Application layer
- Generic orchestrators based on Core entities
- Repository patterns with abstract contracts
- External API client organization by domain

?? **Rich Context System**
- Request validation and mapping
- Middleware-first error handling
- Structured logging integration
- Execution context tracking

?? **Complete Orchestration**
- Orchestrators coordinate business workflows
- Dependency injection across all layers
- Clean separation of concerns
- No business logic in Services/Infrastructure

?? **Flexible Project Structure**
- Conditional API controllers, messaging, workers
- Optional database support (SQL Server, PostgreSQL, Cassandra)
- External API client templates
- GOLD database read-only support

? **Extensive Documentation**
- 5 markdown documents (comprehensive guides)
- Step-by-step implementation examples
- Architecture principles & patterns
- Best practices guide
- Contributor guidelines

?? **Samples & Tests**
- Parameterized test frameworks (xUnit, NUnit, MSTest)
- Unit test examples
- Integration test examples
- Working code patterns

## ?? Documentation Guide

| Document | Purpose | Audience |
|----------|---------|----------|
| [README.md](README.md) | Complete feature reference & parameters | All users |
| [QUICKSTART.md](QUICKSTART.md) | 5-minute setup guide | New users |
| [IMPLEMENTATION.md](IMPLEMENTATION.md) | Architecture internals & deep dive | Developers |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributor guidelines | Contributors |

## ? Quick Start

### Installation

```bash
# Install the template from local path
dotnet new install C:\path\to\ApiTemplate

# Or test without installing first
dotnet new cleanapi \
  --orgName MyOrg \
  --name MyApiService \
  --template-source C:\path\to\ApiTemplate
```

### Create Your First API in 5 Minutes

1. **Create a new project**
   ```bash
   dotnet new cleanapi --orgName MyOrg --name MyApiService
   cd MyApiService
   ```

2. **Define a Core entity** in `src/Core/Entities/`:
   ```csharp
   public class User
   {
       public int Id { get; set; }
       public string Name { get; set; } = string.Empty;
       public string Email { get; set; } = string.Empty;
   }
   ```

3. **Create an Application interface** in `src/Application/Interfaces/`:
   ```csharp
   public interface IUserRepository<T> where T : class
   {
       Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
       Task AddAsync(T entity, CancellationToken cancellationToken = default);
   }
   ```

4. **Implement in Infrastructure** in `src/Infrastructure/Repositories/`:
   ```csharp
   public class UserRepository : IUserRepository<User>
   {
       public async Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
       {
           throw new NotImplementedException();
       }
       
       public async Task AddAsync(User entity, CancellationToken cancellationToken = default)
       {
           throw new NotImplementedException();
       }
   }
   ```

5. **Create an Orchestrator** in `src/Application/Orchestration/`:
   ```csharp
   public class UserOrchestrator<T> where T : User
   {
       private readonly IUserRepository<T> _repository;
       
       public UserOrchestrator(IUserRepository<T> repository)
       {
           _repository = repository;
       }
       
       public async Task<T?> GetUserAsync(int id, CancellationToken cancellationToken = default)
       {
           throw new NotImplementedException();
       }
   }
   ```

6. **Build and run**
   ```bash
   dotnet build
   dotnet run
   ```

## ?? Key Architectural Principles

### 1. Strict Layer Separation
- **Core**: Pure business entities, no framework dependencies
- **Application**: Contracts and orchestration, no implementation
- **Services**: API entry point with thin controllers
- **Infrastructure**: All external dependencies and implementations
- **Startup**: DI orchestration only

### 2. Interface-First Design
- Define contracts in Application before implementing
- All external dependencies are abstractions
- Services layer doesn't know about Infrastructure implementations

### 3. NotImplementedException Placeholders
- All scaffolded methods throw `NotImplementedException()`
- Guides your implementation order
- Prevents accidental usage of incomplete code

### 4. DTO Segregation
- **Services DTOs**: Request/Response models for API contracts
- **Infrastructure DTOs**: External API models (C# records)
- Core entities are never serialized or sent over the wire

### 5. Middleware-First Error Handling
- Controllers remain clean and focused
- Middleware handles validation, mapping, error responses
- Cross-cutting concerns are centralized

## ?? Next Steps

**Ready to build?**
- Follow [QUICKSTART.md](QUICKSTART.md) for step-by-step guide

**Need implementation patterns?**
- Read [IMPLEMENTATION.md](IMPLEMENTATION.md) for detailed examples and best practices

**Want to understand architecture deeply?**
- Review [README.md](README.md) for complete parameter reference and project structure

**Planning to contribute?**
- Check [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and standards

---

**Questions?** ? Check the relevant documentation file above for detailed guidance.

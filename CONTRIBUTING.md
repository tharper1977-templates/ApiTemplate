# Contributing to the Clean Architecture API Template

Thanks for wanting to contribute! This document provides guidelines and helpful pointers for contributors who want to add features, fixes, or improvements to the Clean Architecture API template.

## Quick Checklist for a Contribution

- [ ] Fork the repo and create a feature branch from `master`
- [ ] Open a pull request with a clear title and description
- [ ] Reference any related issue number
- [ ] Include unit or integration tests for behavior changes
- [ ] Verify your changes don't break existing tests
- [ ] Update documentation if you modify features or add new ones
- [ ] Follow the code style and architectural patterns defined below

---

## Code Style & Standards

### Language & Framework

- **Language:** C# 14.0
- **Framework:** .NET 10
- **Architecture:** Clean/Onion Architecture (strict layer separation)

### Code Style Guidelines

1. **Naming Conventions**
   - Use PascalCase for classes, methods, properties, and public fields
   - Use camelCase for local variables and parameters
   - Use UPPER_SNAKE_CASE for constants
   - Use descriptive, pronounceable names (no abbreviations unless standard)

   ```csharp
   public class UserOrchestrator { }           // ? PascalCase
   public int userId;                          // ? camelCase (local var)
   private const string ERROR_MESSAGE = "";    // ? UPPER_SNAKE_CASE
   ```

2. **XML Documentation**
   - All public classes and methods must have XML documentation
   - Document parameters, return values, and exceptions
   - Keep descriptions concise and clear

   ```csharp
   /// <summary>
   /// Gets a user by ID.
   /// </summary>
   /// <param name="id">The user ID.</param>
   /// <param name="cancellationToken">Cancellation token.</param>
   /// <returns>The user if found; otherwise null.</returns>
   public async Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
   {
       throw new NotImplementedException();
   }
   ```

3. **Async/Await**
   - Use `async/await` consistently throughout
   - Always include `CancellationToken` parameter in async methods
   - Use `ConfigureAwait(false)` in library code (already included in templates)

   ```csharp
   public async Task<T> GetAsync(int id, CancellationToken cancellationToken = default)
   {
       throw new NotImplementedException();
   }
   ```

4. **Placeholder Implementations**
   - All scaffolded methods must throw `NotImplementedException()`
   - This is the **first and only statement** in the method body
   - No TODO comments unless explicitly requested
   - The exception guides implementation order

   ```csharp
   public async Task<User> CreateUserAsync(User user, CancellationToken cancellationToken = default)
   {
       throw new NotImplementedException();  // ? First and only statement
   }
   ```

5. **Constructor Injection Only**
   - Use constructor injection exclusively
   - No property injection or service locator pattern
   - Use primary constructors when appropriate (C# 12+)

   ```csharp
   public class UserOrchestrator(
       IUserRepository<User> repository,
       ILogger<UserOrchestrator> logger)  // ? Primary constructor
   {
       // ...
   }
   ```

6. **Guard Clauses**
   - Use guard clauses at the method start
   - Return early to avoid deep nesting

   ```csharp
   public async Task<User?> GetUserAsync(int id)
   {
       if (id <= 0)
           return null;  // ? Guard clause

       return await _repository.GetByIdAsync(id);
   }
   ```

7. **Generics**
   - Use generics for reusable components (repositories, orchestrators)
   - Include clear type constraints

   ```csharp
   public class Repository<T> : IRepository<T> where T : class, IEntity
   {
       // ? Clear constraint
   }
   ```

8. **String Interpolation**
   - Use string interpolation over concatenation or `string.Format()`

   ```csharp
   _logger.LogInformation("User created: {UserId}", user.Id);  // ?
   // Not: "User created: " + user.Id
   ```

---

## Architectural Guidelines

### Layer Responsibilities (Strict Enforcement)

1. **Core Layer**
   - ? Business entities (POCO classes)
   - ? Domain exceptions
   - ? Business constants and enums
   - ? Framework references
   - ? External dependencies

2. **Application Layer**
   - ? Service contracts (interfaces)
   - ? Orchestrators (using generics)
   - ? Specifications (query/validation logic)
   - ? FluentValidation validators
   - ? Implementation details
   - ? DTOs for API contracts (those belong in Services)

3. **Services Layer**
   - ? API controllers (thin, delegation-focused)
   - ? Request/response DTOs
   - ? Middleware
   - ? DI registration for API concerns
   - ? Business logic
   - ? Repository implementations
   - ? External API clients

4. **Infrastructure Layer**
   - ? Repository implementations
   - ? External API clients (organized by domain)
   - ? DTOs for external APIs (C# records only)
   - ? Database contexts
   - ? DI registration for Infrastructure services
   - ? Business logic
   - ? Controllers or middleware

5. **Startup Layer**
   - ? Program.cs (entry point)
   - ? Worker.cs (background services)
   - ? DI orchestration (calling registration methods)
   - ? Service implementations
   - ? Business logic

### DTOs & Data Models

- **Request/Response DTOs** ? `Services.DTOs.Requests` and `Services.DTOs.Responses`
- **External API DTOs** ? `Infrastructure.Clients.{Domain}.DTOs` (use C# records)
- **Core Entities** ? Never serialized or exposed directly
- **Specification DTOs** ? `Application.Specifications` (only if complex)

```csharp
// ? Services project
namespace OrgName.solutionName.Services.DTOs.Requests;
public record CreateUserRequest(string Email, string Name);

// ? Infrastructure project
namespace OrgName.solutionName.Infrastructure.Clients.Payment.DTOs;
public record PaymentRequest(string TransactionId, decimal Amount);

// ? Don't expose Core entities as DTOs
// ? Don't create DTOs in Core layer
```

### Interfaces & Contracts

- Define all external dependencies as interfaces in Application
- Use generic constraints where appropriate
- Name interfaces descriptively (prefer action names)

```csharp
// ? Application layer interface
public interface IUserRepository<T> where T : User
{
    Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task AddAsync(T entity, CancellationToken cancellationToken = default);
}

// ? Implemented in Infrastructure
public class UserRepository : IUserRepository<User>
{
    // Implementation
}

// ? Don't define interfaces in Infrastructure
```

### Controllers

- Keep controllers **thin and focused**
- Delegate all business logic to orchestrators
- Map DTOs to entities, not the other way around
- Let middleware handle error responses

```csharp
// ? Thin controller
[HttpPost]
public async Task<ActionResult> CreateUser(CreateUserRequest request, CancellationToken cancellationToken)
{
    var user = new User { Email = request.Email, Name = request.Name };
    await _orchestrator.CreateUserAsync(user, cancellationToken);
    return Ok();
}

// ? Don't put business logic in controllers
[HttpPost]
public async Task<ActionResult> CreateUser(CreateUserRequest request)
{
    if (string.IsNullOrEmpty(request.Email)) return BadRequest();
    var user = new User { Email = request.Email };
    if (user.IsValidEmail()) {
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
    }
    return Ok();  // Too much logic!
}
```

### Dependency Injection

- **Application** layer registers orchestrators and validators
- **Infrastructure** layer registers repositories and clients
- **Services** layer registers API-specific components
- **Startup** calls all three in order

```csharp
// ? Application
public static IServiceCollection AddApplicationServices(this IServiceCollection services)
{
    services.AddScoped(typeof(UserOrchestrator<>));
    return services;
}

// ? Infrastructure
public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
{
    services.AddScoped(typeof(IUserRepository<>), typeof(UserRepository));
    services.AddScoped<IPaymentClient, PaymentClient>();
    return services;
}

// ? Startup
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices();
builder.Services.AddServicesLayer();
```

---

## Template Organization

### Project Structure

The template uses conditional generation based on parameters. When contributing:

1. **Always use parameter checks** in `.template.config/template.json`
2. **Keep conditional logic minimal** - prefer generating files then excluding via conditions
3. **Document any new parameters** in the README.md
4. **Test with different parameter combinations**

### File & Folder Naming

- Use PascalCase for folders
- Use PascalCase for class files (one class per file)
- Use consistent naming for interfaces (I + PascalCase)
- Group related files in subdirectories

```
src/
??? Core/
?   ??? Entities/
?   ?   ??? User.cs
?   ?   ??? Product.cs
?   ??? Exceptions/
?   ?   ??? DomainException.cs
?   ??? Constants/
?   ??? Enums/
?       ??? UserRole.cs
??? Application/
    ??? Interfaces/
    ?   ??? IUserRepository.cs
    ?   ??? IProductRepository.cs
    ??? Orchestration/
    ?   ??? UserOrchestrator.cs
    ?   ??? ProductOrchestrator.cs
    ??? Specifications/
        ??? ActiveUsersSpecification.cs
```

---

## Testing Requirements

### Unit Tests

- Test Core and Application layers
- Mock external dependencies
- Use `xUnit`, `NUnit`, or `MSTest` (based on template selection)
- Aim for high coverage of business logic

```csharp
[Fact]  // or [Test] for NUnit, [TestMethod] for MSTest
public async Task CreateUser_WithValidEmail_ShouldSucceed()
{
    // Arrange
    var repository = new Mock<IUserRepository<User>>();
    var orchestrator = new UserOrchestrator<User>(repository.Object, _logger);

    // Act
    var result = await orchestrator.CreateUserAsync(new User { Email = "test@example.com" });

    // Assert
    Assert.NotNull(result);
    repository.Verify(r => r.AddAsync(It.IsAny<User>(), default), Times.Once);
}
```

### Integration Tests

- Test full workflows with real dependencies (in-memory DB, etc.)
- Focus on critical paths
- Clean up test data after each test

```csharp
[Fact]
public async Task CreateAndRetrieveUser_WorksEndToEnd()
{
    // Arrange - Set up real database
    var options = new DbContextOptionsBuilder<ApplicationDbContext>()
        .UseInMemoryDatabase("TestDb")
        .Options;

    using var context = new ApplicationDbContext(options);
    var repository = new UserRepository(context, _logger);
    var user = new User { Email = "test@example.com" };

    // Act
    await repository.AddAsync(user);
    var retrieved = await repository.GetByIdAsync(user.Id);

    // Assert
    Assert.NotNull(retrieved);
    Assert.Equal(user.Email, retrieved.Email);
}
```

### Test Naming

Use the pattern: `{Method}_{Scenario}_{Expected}`

```csharp
CreateUser_WithValidEmail_ReturnsUser()     // ?
GetUser_WithInvalidId_ReturnsNull()         // ?
ProcessPayment_WithInsufficientFunds_ThrowsException()  // ?

CreateUserTest()                            // ? Not descriptive
TestCreation()                              // ? Not clear
UserTest()                                  // ? Too vague
```

---

## Adding New Features

### Before You Start

1. **Open an issue** to discuss the feature
2. **Understand the architecture** - read IMPLEMENTATION.md
3. **Plan the change** - which layers are affected?
4. **Check existing patterns** - follow established conventions

### Adding a New Orchestrator

```csharp
// 1. Define the interface in Application
public interface IOrderOrchestrator<T> where T : Order
{
    Task<T> CreateOrderAsync(T order, CancellationToken cancellationToken = default);
    Task<T?> GetOrderAsync(int id, CancellationToken cancellationToken = default);
}

// 2. Implement in Application (as concrete class, or keep as interface for Infrastructure)
public class OrderOrchestrator<T> : IOrderOrchestrator<T> where T : Order, new()
{
    private readonly IOrderRepository<T> _repository;

    public OrderOrchestrator(IOrderRepository<T> repository)
    {
        _repository = repository;
    }

    public async Task<T> CreateOrderAsync(T order, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    public async Task<T?> GetOrderAsync(int id, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}

// 3. Register in DI
public static IServiceCollection AddApplicationServices(this IServiceCollection services)
{
    services.AddScoped(typeof(IOrderOrchestrator<>), typeof(OrderOrchestrator<>));
    return services;
}

// 4. Test with unit tests
```

### Adding a New Repository

```csharp
// 1. Define interface in Application
public interface IOrderRepository<T> where T : Order
{
    Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task AddAsync(T entity, CancellationToken cancellationToken = default);
}

// 2. Implement in Infrastructure
public class OrderRepository : IOrderRepository<Order>
{
    private readonly ApplicationDbContext _context;

    public OrderRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Order?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    public async Task AddAsync(Order entity, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}

// 3. Register in DI
public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
{
    services.AddScoped(typeof(IOrderRepository<>), typeof(OrderRepository));
    return services;
}

// 4. Test with integration tests
```

### Adding a New External API Client

```csharp
// 1. Create domain folder in Infrastructure/Clients
// src/Infrastructure/Clients/Shipping/

// 2. Define interface
public interface IShippingClient
{
    Task<ShippingQuoteResponse> GetQuoteAsync(ShippingQuoteRequest request);
}

// 3. Implement
public class ShippingClient : IShippingClient
{
    private readonly HttpClient _httpClient;

    public ShippingClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<ShippingQuoteResponse> GetQuoteAsync(ShippingQuoteRequest request)
    {
        throw new NotImplementedException();
    }
}

// 4. Create DTOs (records) in Clients/Shipping/DTOs/
public record ShippingQuoteRequest(string Origin, string Destination);
public record ShippingQuoteResponse(decimal Cost, int DaysToDeliver);

// 5. Register in DI
services.AddHttpClient<IShippingClient, ShippingClient>();

// 6. Use in orchestrator via injection
```

---

## Pull Request Process

1. **Fork** the repository
2. **Create a feature branch** from `master`
   ```bash
   git checkout -b feature/user-orchestrator
   ```

3. **Make your changes** following the guidelines above

4. **Write tests** for your changes
   ```bash
   dotnet test
   ```

5. **Verify no build errors**
   ```bash
   dotnet build
   ```

6. **Commit with clear messages**
   ```bash
   git commit -m "feat: add user orchestrator with CRUD operations"
   ```

7. **Push your branch**
   ```bash
   git push origin feature/user-orchestrator
   ```

8. **Open a Pull Request** with:
   - Clear title: `feat: add user orchestrator` or `fix: controller delegation issue`
   - Description of changes
   - Related issue number (if any)
   - Screenshots or examples (if applicable)

### PR Checklist

- [ ] Changes follow architectural guidelines
- [ ] Code style is consistent
- [ ] XML documentation is complete
- [ ] All public APIs are documented
- [ ] Unit/Integration tests are included
- [ ] All tests pass (`dotnet test`)
- [ ] Solution builds without warnings (`dotnet build`)
- [ ] No sensitive data (API keys, credentials) included
- [ ] Documentation updated (README.md, etc.)

---

## PR Review Criteria

Your PR will be reviewed against:

1. ? **Architectural Integrity** - Does it follow clean architecture principles?
2. ? **Code Quality** - Is it consistent with the codebase?
3. ? **Test Coverage** - Are tests included and meaningful?
4. ? **Documentation** - Is it well-documented?
5. ? **Breaking Changes** - Does it break existing functionality?

---

## Reporting Issues

Use GitHub Issues to report:

- **Bugs**: Provide reproducible steps, expected vs actual behavior
- **Feature Requests**: Describe the use case and expected behavior
- **Documentation Issues**: Point out unclear or missing documentation

**Issue Title Format:**
```
[BUG] Controller not delegating to orchestrator
[FEATURE] Add specification pattern example
[DOCS] Clarify middleware configuration
```

---

## Questions?

- **Architecture:** See [IMPLEMENTATION.md](IMPLEMENTATION.md)
- **Quick Start:** See [QUICKSTART.md](QUICKSTART.md)
- **API Reference:** See [README.md](README.md)
- **Issues:** Open a GitHub Issue

---

**Thank you for contributing!** Your help makes this template better for everyone. Contributions are reviewed promptly, and we appreciate your effort to follow these guidelines. ??

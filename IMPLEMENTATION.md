# Implementation Guide

Deep dive into the Clean Architecture API template architecture, patterns, and best practices.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Layer Responsibilities](#layer-responsibilities)
3. [Core Patterns](#core-patterns)
4. [Dependency Injection Strategy](#dependency-injection-strategy)
5. [Working with Entities](#working-with-entities)
6. [Creating Orchestrators](#creating-orchestrators)
7. [Building Repositories](#building-repositories)
8. [External API Clients](#external-api-clients)
9. [Middleware & Request Handling](#middleware--request-handling)
10. [Validation & Specifications](#validation--specifications)
11. [Testing Strategies](#testing-strategies)
12. [Common Patterns & Anti-Patterns](#common-patterns--anti-patterns)

---

## Architecture Overview

The template implements a **strict onion/adapter architecture**:

```
                 ???????????????????????????????
                 ?      Startup (Entry)        ?
                 ?  - Program.cs               ?
                 ?  - Worker.cs                ?
                 ?  - DI Orchestration         ?
                 ???????????????????????????????
                            ?
         ???????????????????????????????????????
         ?                  ?                  ?
    ????????????      ??????????????    ???????????????
    ? Services ?      ?Application ?    ?Infrastructure
    ? - API    ?      ? - Contracts?    ? - Repos
    ? - DTOs   ?      ? - Orchest. ?    ? - Clients
    ? - Middle ?      ? - Specs    ?    ? - DB Contexts
    ????????????      ??????????????    ???????????????
         ?                  ?                ?
         ?????????????????????????????????????
                            ?
         ???????????????????????????????????????
         ?   Core (Pure Domain Logic)          ?
         ?  - Entities                         ?
         ?  - Exceptions                       ?
         ?  - Constants & Enums                ?
         ???????????????????????????????????????
```

### Key Principle: Dependency Flow

**Dependencies ONLY point inward** ? No Core depends on other layers, no Application depends on Services/Infrastructure.

---

## Layer Responsibilities

### 1. Core Layer: Pure Domain Logic

**Purpose:** Business entities and domain rules  
**Location:** `src/Core/`

**What goes here:**
- ? Business entities (POCO classes)
- ? Domain exceptions
- ? Business constants and enums
- ? Business validation rules (as methods on entities)

**What NEVER goes here:**
- ? Framework references (EF Core, ASP.NET, etc.)
- ? External dependencies
- ? Data access code
- ? Infrastructure concerns
- ? DTOs or request/response models

**Example:**

```csharp
namespace OrgName.solutionName.Core.Entities;

/// <summary>
/// Represents a user in the system (pure domain object).
/// </summary>
public class User
{
    /// <summary>
    /// Gets or sets the user ID.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Gets or sets the user's email address.
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the user's role.
    /// </summary>
    public UserRole Role { get; set; } = UserRole.User;

    /// <summary>
    /// Validates the user's email format (pure business rule).
    /// </summary>
    /// <returns>True if email is valid; otherwise false.</returns>
    public bool IsEmailValid()
    {
        return Email.Contains("@") && Email.Contains(".");
    }

    /// <summary>
    /// Determines if the user is an administrator.
    /// </summary>
    /// <returns>True if user is admin; otherwise false.</returns>
    public bool IsAdmin() => Role == UserRole.Admin;
}

/// <summary>
/// User role enumeration.
/// </summary>
public enum UserRole
{
    User = 0,
    Moderator = 1,
    Admin = 2
}

/// <summary>
/// Domain exception for user-related errors.
/// </summary>
public class UserDomainException : Exception
{
    public UserDomainException(string message) : base(message) { }
}
```

---

### 2. Application Layer: Contracts & Orchestration

**Purpose:** Business workflow coordination without implementation details  
**Location:** `src/Application/`

**What goes here:**
- ? Service contracts (interfaces)
- ? Orchestrators that coordinate workflows
- ? Specifications (query or validation specs)
- ? FluentValidation validators
- ? Application-level DTOs (optional, for complex specs)

**What NEVER goes here:**
- ? Implementation of repositories or external clients
- ? Database queries or context
- ? External API calls
- ? Request/response DTOs (those belong in Services)
- ? Infrastructure setup

**Interfaces Example:**

```csharp
namespace OrgName.solutionName.Application.Interfaces;

using OrgName.solutionName.Core.Entities;

/// <summary>
/// Repository contract for user data access.
/// Uses generic T so implementation is flexible.
/// </summary>
/// <typeparam name="T">The user entity type.</typeparam>
public interface IUserRepository<T> where T : User
{
    /// <summary>
    /// Gets a user by ID.
    /// </summary>
    Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets all users matching a specification.
    /// </summary>
    Task<IEnumerable<T>> GetAsync(ISpecification<T> spec, CancellationToken cancellationToken = default);

    /// <summary>
    /// Adds a new user.
    /// </summary>
    Task AddAsync(T entity, CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates an existing user.
    /// </summary>
    Task UpdateAsync(T entity, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a user.
    /// </summary>
    Task DeleteAsync(T entity, CancellationToken cancellationToken = default);
}
```

**Orchestrator Example:**

```csharp
namespace OrgName.solutionName.Application.Orchestration;

using Microsoft.Extensions.Logging;
using OrgName.solutionName.Core.Entities;
using OrgName.solutionName.Application.Interfaces;

/// <summary>
/// Orchestrates user business workflows.
/// Does NOT implement details; just coordinates contracts.
/// </summary>
/// <typeparam name="T">The user entity type.</typeparam>
public class UserOrchestrator<T> where T : User, new()
{
    private readonly IUserRepository<T> _repository;
    private readonly IUserValidator<T> _validator;
    private readonly ILogger<UserOrchestrator<T>> _logger;

    public UserOrchestrator(
        IUserRepository<T> repository,
        IUserValidator<T> validator,
        ILogger<UserOrchestrator<T>> logger)
    {
        _repository = repository;
        _validator = validator;
        _logger = logger;
    }

    /// <summary>
    /// Creates a new user with validation.
    /// Delegates to contracts; no implementation details here.
    /// </summary>
    public async Task<T> CreateUserAsync(T user, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating user with email: {Email}", user.Email);

        // Orchestrates the workflow: validate ? persist
        var validationResult = await _validator.ValidateAsync(user, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new UserDomainException($"Validation failed: {validationResult.Errors.First()}");
        }

        await _repository.AddAsync(user, cancellationToken);
        _logger.LogInformation("User created successfully: {UserId}", user.Id);

        return user;
    }

    /// <summary>
    /// Retrieves a user and checks authorization.
    /// </summary>
    public async Task<T?> GetUserByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Retrieving user: {UserId}", id);
        throw new NotImplementedException();
    }
}
```

**Specification Example:**

```csharp
namespace OrgName.solutionName.Application.Specifications;

using OrgName.solutionName.Core.Entities;

/// <summary>
/// Specification for finding active admin users.
/// Encapsulates complex query logic.
/// </summary>
public class ActiveAdminsSpecification : ISpecification<User>
{
    public Expression<Func<User, bool>> Criteria { get; } = 
        u => u.IsAdmin() && u.IsActive;

    public IReadOnlyList<Expression<Func<User, object>>> Includes { get; } = 
        new List<Expression<Func<User, object>>>();

    public IReadOnlyList<string> IncludeStrings { get; } = 
        new List<string>();

    public Expression<Func<User, object>>? OrderBy { get; }
    public Expression<Func<User, object>>? OrderByDescending { get; }
    public int? Take { get; }
    public int? Skip { get; }
    public bool IsPagingEnabled { get; }
}
```

---

### 3. Services Layer: API Entry Point

**Purpose:** Handle external access (HTTP, messaging, etc.)  
**Location:** `src/Services/`

**What goes here:**
- ? API controllers (thin, delegation-focused)
- ? Request/response DTOs
- ? Middleware for cross-cutting concerns
- ? DI registration for Services-specific concerns
- ? Inbound messaging consumers

**What NEVER goes here:**
- ? Business logic
- ? Repository implementations
- ? External API clients
- ? Database contexts
- ? Infrastructure details

**Controller Example (THIN!):**

```csharp
namespace OrgName.solutionName.Services.Controllers;

using Microsoft.AspNetCore.Mvc;
using OrgName.solutionName.Application.Orchestration;
using OrgName.solutionName.Core.Entities;
using OrgName.solutionName.Services.DTOs.Requests;
using OrgName.solutionName.Services.DTOs.Responses;

/// <summary>
/// API controller for user operations.
/// Controllers are THIN - they delegate to orchestrators.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserOrchestrator<User> _orchestrator;
    private readonly ILogger<UsersController> _logger;

    public UsersController(UserOrchestrator<User> orchestrator, ILogger<UsersController> logger)
    {
        _orchestrator = orchestrator;
        _logger = logger;
    }

    /// <summary>
    /// Gets a user by ID.
    /// Controller maps DTO ? Entity ? Orchestrator ? DTO ? Response.
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<UserResponse>> GetUser(int id, CancellationToken cancellationToken)
    {
        var user = await _orchestrator.GetUserByIdAsync(id, cancellationToken);
        if (user == null)
            return NotFound();

        return Ok(new UserResponse(user.Id, user.Email, user.Role.ToString()));
    }

    /// <summary>
    /// Creates a new user.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<UserResponse>> CreateUser(
        CreateUserRequest request,
        CancellationToken cancellationToken)
    {
        var user = new User { Email = request.Email, Role = request.Role };
        await _orchestrator.CreateUserAsync(user, cancellationToken);

        return CreatedAtAction(nameof(GetUser), new { id = user.Id },
            new UserResponse(user.Id, user.Email, user.Role.ToString()));
    }
}
```

**Request DTO Example:**

```csharp
namespace OrgName.solutionName.Services.DTOs.Requests;

/// <summary>
/// Request model for creating a new user.
/// DTOs are records - immutable and lightweight.
/// </summary>
public record CreateUserRequest(
    string Email,
    string Role);
```

**Response DTO Example:**

```csharp
namespace OrgName.solutionName.Services.DTOs.Responses;

/// <summary>
/// Response model for user queries.
/// </summary>
public record UserResponse(
    int Id,
    string Email,
    string Role);
```

**Middleware Example:**

```csharp
namespace OrgName.solutionName.Services.Middleware;

using System.Net;
using OrgName.solutionName.Core.Exceptions;

/// <summary>
/// Global exception handling middleware.
/// Catches errors and returns appropriate HTTP responses.
/// Controllers stay clean - middleware handles unhappy paths.
/// </summary>
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (UserDomainException ex)
        {
            _logger.LogWarning("Domain validation error: {Message}", ex.Message);
            context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            await context.Response.WriteAsJsonAsync(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception");
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            await context.Response.WriteAsJsonAsync(new { error = "An unexpected error occurred." });
        }
    }
}
```

---

### 4. Infrastructure Layer: Implementations & External Dependencies

**Purpose:** Implement contracts and manage external systems  
**Location:** `src/Infrastructure/`

**What goes here:**
- ? Repository implementations
- ? External API clients (organized by domain)
- ? Database contexts (EF Core, Dapper, etc.)
- ? DTOs for external APIs (C# records)
- ? DI registration for Infrastructure services

**What NEVER goes here:**
- ? Business logic
- ? Controllers
- ? Middleware
- ? Request/response DTOs

**Repository Implementation Example:**

```csharp
namespace OrgName.solutionName.Infrastructure.Repositories;

using Microsoft.EntityFrameworkCore;
using OrgName.solutionName.Core.Entities;
using OrgName.solutionName.Application.Interfaces;

/// <summary>
/// EF Core implementation of user repository.
/// Implements the contract defined in Application layer.
/// </summary>
public class UserRepository : IUserRepository<User>
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<UserRepository> _logger;

    public UserRepository(ApplicationDbContext context, ILogger<UserRepository> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Querying user by ID: {UserId}", id);
        return await _context.Users.FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public async Task<IEnumerable<User>> GetAsync(
        ISpecification<User> spec,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Users.AsQueryable();
        query = spec.Criteria != null ? query.Where(spec.Criteria) : query;
        return await query.ToListAsync(cancellationToken);
    }

    public async Task AddAsync(User entity, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Adding user: {Email}", entity.Email);
        _context.Users.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(User entity, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    public async Task DeleteAsync(User entity, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}
```

**External API Client Example:**

```csharp
namespace OrgName.solutionName.Infrastructure.Clients.Payment;

using OrgName.solutionName.Infrastructure.Clients.Payment.DTOs;

/// <summary>
/// HTTP client for payment service integration.
/// Clients are organized by domain (Payment, Notification, etc.).
/// </summary>
public interface IPaymentClient
{
    Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request, CancellationToken cancellationToken = default);
}

/// <summary>
/// Implementation of payment client.
/// </summary>
public class PaymentClient : IPaymentClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PaymentClient> _logger;

    public PaymentClient(HttpClient httpClient, ILogger<PaymentClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<PaymentResponse> ProcessPaymentAsync(
        PaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Processing payment for amount: {Amount}", request.Amount);
        throw new NotImplementedException();
    }
}

/// <summary>
/// External payment service request DTO (record).
/// </summary>
public record PaymentRequest(
    string TransactionId,
    decimal Amount,
    string Currency);

/// <summary>
/// External payment service response DTO (record).
/// </summary>
public record PaymentResponse(
    string TransactionId,
    bool IsSuccessful,
    string? FailureReason = null);
```

---

### 5. Startup Layer: Entry Point & DI Orchestration

**Purpose:** Bootstrap the application and wire up dependencies  
**Location:** `src/Startup/`

**What goes here:**
- ? Program.cs (entry point)
- ? Worker.cs (background services)
- ? appsettings.json (configuration)

**What NEVER goes here:**
- ? Business logic
- ? Service implementations
- ? Repository implementations

**Program.cs Example:**

```csharp
namespace OrgName.solutionName.Startup;

using Microsoft.Extensions.Hosting;
using OrgName.solutionName.Application.DependencyInjection;
using OrgName.solutionName.Infrastructure.DependencyInjection;
using OrgName.solutionName.Services.DependencyInjection;

/// <summary>
/// Application entry point.
/// Orchestrates DI from all layers.
/// </summary>
public class Program
{
    /// <summary>
    /// Main application entry point.
    /// </summary>
    public static void Main(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);

        // Register services from each layer (order matters!)
        builder.Services.AddApplicationServices();
        builder.Services.AddInfrastructureServices();
        builder.Services.AddServicesLayer();

        // Register hosted services (workers)
        builder.Services.AddHostedService<Worker>();

        // Build and run
        var host = builder.Build();
        host.Run();
    }
}
```

---

## Core Patterns

### 1. Generic Repositories

Use generics to support multiple entity variations:

```csharp
// In Application
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id);
    Task AddAsync(T entity);
}

// Orchestrator uses generic
public class Orchestrator<T> where T : BaseEntity, new()
{
    private readonly IRepository<T> _repository;
    // ...
}

// Infrastructure implements the interface
public class Repository<T> : IRepository<T> where T : class
{
    // ...
}
```

### 2. Specification Pattern

Encapsulate query logic:

```csharp
public interface ISpecification<T>
{
    Expression<Func<T, bool>> Criteria { get; }
    IReadOnlyList<Expression<Func<T, object>>> Includes { get; }
}

// Usage in repository
public async Task<IEnumerable<T>> GetAsync(ISpecification<T> spec)
{
    var query = _context.Set<T>().AsQueryable();
    if (spec.Criteria != null)
        query = query.Where(spec.Criteria);
    
    foreach (var include in spec.Includes)
        query = query.Include(include);
    
    return await query.ToListAsync();
}
```

### 3. Result Pattern

Avoid throwing exceptions for expected errors:

```csharp
public class Result<T>
{
    public bool IsSuccess { get; set; }
    public T? Data { get; set; }
    public string? ErrorMessage { get; set; }

    public static Result<T> Success(T data) =>
        new() { IsSuccess = true, Data = data };

    public static Result<T> Failure(string message) =>
        new() { IsSuccess = false, ErrorMessage = message };
}

// Usage
public async Task<Result<User>> GetUserAsync(int id)
{
    var user = await _repository.GetByIdAsync(id);
    return user == null
        ? Result<User>.Failure("User not found")
        : Result<User>.Success(user);
}
```

---

## Dependency Injection Strategy

### Application Layer

```csharp
namespace OrgName.solutionName.Application.DependencyInjection;

using Microsoft.Extensions.DependencyInjection;

public static class ApplicationServiceRegistration
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Register orchestrators (generic)
        services.AddScoped(typeof(UserOrchestrator<>));
        services.AddScoped(typeof(ProductOrchestrator<>));

        // Register validators
        // services.AddValidatorsFromAssembly(typeof(ApplicationServiceRegistration).Assembly);

        return services;
    }
}
```

### Infrastructure Layer

```csharp
namespace OrgName.solutionName.Infrastructure.DependencyInjection;

using Microsoft.Extensions.DependencyInjection;
using OrgName.solutionName.Application.Interfaces;
using OrgName.solutionName.Infrastructure.Repositories;
using OrgName.solutionName.Infrastructure.Clients.Payment;

public static class InfrastructureServiceRegistration
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {
        // Register repositories (generic)
        services.AddScoped(typeof(IUserRepository<>), typeof(UserRepository));
        services.AddScoped(typeof(IProductRepository<>), typeof(ProductRepository));

        // Register external clients
        services.AddScoped<IPaymentClient, PaymentClient>();
        services.AddHttpClient<PaymentClient>();

        // Register database context
        services.AddDbContext<ApplicationDbContext>();

        return services;
    }
}
```

### Services Layer

```csharp
namespace OrgName.solutionName.Services.DependencyInjection;

using Microsoft.Extensions.DependencyInjection;

public static class ServicesRegistration
{
    public static IServiceCollection AddServicesLayer(this IServiceCollection services)
    {
        // Register controllers
        services.AddControllers();

        // Register middleware
        // services.AddScoped<ExceptionHandlingMiddleware>();

        // Register Swagger (if enabled)
        services.AddSwaggerGen();

        // Register health checks (if enabled)
        services.AddHealthChecks();

        return services;
    }
}
```

### Startup Layer

```csharp
public static void Main(string[] args)
{
    var builder = Host.CreateApplicationBuilder(args);

    // Call DI registration from each layer IN ORDER
    builder.Services.AddApplicationServices();      // First: contracts & orchestrators
    builder.Services.AddInfrastructureServices();   // Second: implementations
    builder.Services.AddServicesLayer();            // Third: API-specific

    var host = builder.Build();
    host.Run();
}
```

---

## Working with Entities

### Entity Design Principles

1. **Keep entities pure** - no framework attributes unless necessary
2. **Business logic belongs in entities** - validation, calculations
3. **Use getters/setters for encapsulation**
4. **No direct dependencies** on external systems

```csharp
public class Order
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public List<OrderLine> Lines { get; set; } = new();
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public decimal TotalAmount { get; private set; }

    /// <summary>
    /// Pure business logic - can be unit tested without mocks.
    /// </summary>
    public void RecalculateTotal()
    {
        TotalAmount = Lines.Sum(l => l.Quantity * l.UnitPrice);
    }

    /// <summary>
    /// Another business rule.
    /// </summary>
    public bool CanBeCancelled()
    {
        return Status == OrderStatus.Pending || Status == OrderStatus.Processing;
    }

    /// <summary>
    /// Validates state.
    /// </summary>
    public bool IsValid()
    {
        return CustomerId > 0 && Lines.Count > 0 && TotalAmount > 0;
    }
}

public enum OrderStatus
{
    Pending,
    Processing,
    Shipped,
    Cancelled
}
```

---

## Creating Orchestrators

Orchestrators coordinate workflows without implementation:

```csharp
public class OrderOrchestrator<T> where T : Order, new()
{
    private readonly IOrderRepository<T> _orderRepository;
    private readonly IPaymentClient _paymentClient;
    private readonly IOrderValidator<T> _validator;
    private readonly ILogger<OrderOrchestrator<T>> _logger;

    public OrderOrchestrator(
        IOrderRepository<T> orderRepository,
        IPaymentClient paymentClient,
        IOrderValidator<T> validator,
        ILogger<OrderOrchestrator<T>> logger)
    {
        _orderRepository = orderRepository;
        _paymentClient = paymentClient;
        _validator = validator;
        _logger = logger;
    }

    /// <summary>
    /// Creates an order: validate ? process payment ? persist.
    /// Orchestrates workflow but doesn't implement details.
    /// </summary>
    public async Task<T> CreateOrderAsync(T order, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating order for customer: {CustomerId}", order.CustomerId);

        // Step 1: Validate
        var validation = await _validator.ValidateAsync(order, cancellationToken);
        if (!validation.IsValid)
            throw new OrderDomainException("Order validation failed");

        // Step 2: Recalculate (business rule)
        order.RecalculateTotal();

        // Step 3: Process payment (delegated to contract)
        var payment = new PaymentRequest(
            Guid.NewGuid().ToString(),
            order.TotalAmount,
            "USD");
        var paymentResult = await _paymentClient.ProcessPaymentAsync(payment, cancellationToken);

        if (!paymentResult.IsSuccessful)
            throw new OrderDomainException($"Payment failed: {paymentResult.FailureReason}");

        // Step 4: Persist (delegated to contract)
        order.Status = OrderStatus.Processing;
        await _orderRepository.AddAsync(order, cancellationToken);

        _logger.LogInformation("Order created successfully: {OrderId}", order.Id);
        return order;
    }
}
```

---

## Building Repositories

### Generic Repository Pattern

```csharp
/// <summary>
/// Base repository for all entities.
/// </summary>
public class Repository<T> : IRepository<T> where T : class, IEntity
{
    protected readonly ApplicationDbContext Context;
    protected readonly DbSet<T> DbSet;
    protected readonly ILogger<Repository<T>> Logger;

    public Repository(ApplicationDbContext context, ILogger<Repository<T>> logger)
    {
        Context = context;
        DbSet = context.Set<T>();
        Logger = logger;
    }

    public virtual async Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        Logger.LogInformation("Getting {Entity} by ID: {Id}", typeof(T).Name, id);
        return await DbSet.FindAsync(new object[] { id }, cancellationToken: cancellationToken);
    }

    public virtual async Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await DbSet.ToListAsync(cancellationToken);
    }

    public virtual async Task AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        Logger.LogInformation("Adding {Entity}", typeof(T).Name);
        await DbSet.AddAsync(entity, cancellationToken);
        await Context.SaveChangesAsync(cancellationToken);
    }

    public virtual async Task UpdateAsync(T entity, CancellationToken cancellationToken = default)
    {
        Logger.LogInformation("Updating {Entity}", typeof(T).Name);
        DbSet.Update(entity);
        await Context.SaveChangesAsync(cancellationToken);
    }

    public virtual async Task DeleteAsync(T entity, CancellationToken cancellationToken = default)
    {
        Logger.LogInformation("Deleting {Entity}", typeof(T).Name);
        DbSet.Remove(entity);
        await Context.SaveChangesAsync(cancellationToken);
    }
}

/// <summary>
/// Specialized repository for a specific entity.
/// Adds domain-specific queries.
/// </summary>
public class UserRepository : Repository<User>, IUserRepository<User>
{
    public UserRepository(ApplicationDbContext context, ILogger<UserRepository> logger)
        : base(context, logger)
    {
    }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        Logger.LogInformation("Getting user by email: {Email}", email);
        return await DbSet.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }

    public async Task<IEnumerable<User>> GetAdminsAsync(CancellationToken cancellationToken = default)
    {
        Logger.LogInformation("Getting all admin users");
        return await DbSet.Where(u => u.IsAdmin()).ToListAsync(cancellationToken);
    }
}
```

---

## External API Clients

### Client Organization

Group clients by domain:

```
src/Infrastructure/Clients/
??? Payment/
?   ??? IPaymentClient.cs
?   ??? PaymentClient.cs
?   ??? DTOs/
?       ??? PaymentRequest.cs
?       ??? PaymentResponse.cs
??? Notification/
?   ??? INotificationClient.cs
?   ??? NotificationClient.cs
?   ??? DTOs/
?       ??? EmailRequest.cs
?       ??? NotificationResponse.cs
??? User/
    ??? IUserServiceClient.cs
    ??? UserServiceClient.cs
    ??? DTOs/
        ??? UserDto.cs
        ??? UserSearchResponse.cs
```

### Client Implementation

```csharp
/// <summary>
/// Payment service client.
/// </summary>
public interface IPaymentClient
{
    Task<PaymentResponse> ProcessPaymentAsync(
        PaymentRequest request,
        CancellationToken cancellationToken = default);

    Task<PaymentResponse> RefundAsync(
        string transactionId,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// HTTP implementation of payment client.
/// </summary>
public class PaymentClient : IPaymentClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PaymentClient> _logger;
    private readonly PaymentSettings _settings;

    public PaymentClient(
        HttpClient httpClient,
        ILogger<PaymentClient> logger,
        IOptions<PaymentSettings> settings)
    {
        _httpClient = httpClient;
        _logger = logger;
        _settings = settings.Value;
    }

    public async Task<PaymentResponse> ProcessPaymentAsync(
        PaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Processing payment: {TransactionId}", request.TransactionId);
        throw new NotImplementedException();
    }

    public async Task<PaymentResponse> RefundAsync(
        string transactionId,
        CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// External payment service DTOs (records).
/// </summary>
public record PaymentRequest(
    string TransactionId,
    decimal Amount,
    string Currency);

public record PaymentResponse(
    string TransactionId,
    bool IsSuccessful,
    string? FailureReason = null);
```

---

## Middleware & Request Handling

### Exception Handling Middleware

```csharp
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (OrderDomainException ex)
        {
            _logger.LogWarning("Domain validation error: {Message}", ex.Message);
            await HandleDomainExceptionAsync(context, ex);
        }
        catch (NotFoundException ex)
        {
            _logger.LogWarning("Not found: {Message}", ex.Message);
            await HandleNotFoundAsync(context, ex);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error");
            await HandleUnexpectedExceptionAsync(context, ex);
        }
    }

    private static Task HandleDomainExceptionAsync(HttpContext context, DomainException ex)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = StatusCodes.Status400BadRequest;
        return context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }

    private static Task HandleNotFoundAsync(HttpContext context, NotFoundException ex)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = StatusCodes.Status404NotFound;
        return context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }

    private static Task HandleUnexpectedExceptionAsync(HttpContext context, Exception ex)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        return context.Response.WriteAsJsonAsync(new { error = "An unexpected error occurred." });
    }
}
```

### Request Mapping Middleware

```csharp
/// <summary>
/// Maps incoming request DTOs to domain entities.
/// </summary>
public class RequestMappingMiddleware
{
    private readonly RequestDelegate _next;

    public RequestMappingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Example: Automatically map request DTOs to entities
        // (In practice, use AutoMapper or Mapster)
        await _next(context);
    }
}
```

### Registering Middleware

```csharp
public class Program
{
    public static void Main(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);

        builder.Services.AddApplicationServices();
        builder.Services.AddInfrastructureServices();
        builder.Services.AddServicesLayer();

        var app = builder.Build();

        // Use middleware IN ORDER
        app.UseExceptionHandlingMiddleware();
        app.UseRequestMappingMiddleware();
        app.UseRouting();
        app.MapControllers();

        app.Run();
    }
}
```

---

## Validation & Specifications

### FluentValidation

```csharp
public class CreateOrderRequestValidator : AbstractValidator<CreateOrderRequest>
{
    public CreateOrderRequestValidator()
    {
        RuleFor(x => x.CustomerId)
            .GreaterThan(0).WithMessage("Customer ID must be valid");

        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("Order must contain at least one item")
            .Must(items => items.All(i => i.Quantity > 0)).WithMessage("All items must have positive quantity");

        RuleFor(x => x.ShippingAddress)
            .NotEmpty().WithMessage("Shipping address is required");
    }
}

// Usage in orchestrator
public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
{
    var validator = new CreateOrderRequestValidator();
    var result = await validator.ValidateAsync(request);
    
    if (!result.IsValid)
        throw new ValidationException(result.Errors);
    
    // Continue with order creation...
}
```

### Custom Validators

```csharp
public interface IEntityValidator<T> where T : class
{
    Task<ValidationResult> ValidateAsync(T entity, CancellationToken cancellationToken = default);
}

public class OrderValidator : IEntityValidator<Order>
{
    private readonly IOrderRepository<Order> _repository;

    public OrderValidator(IOrderRepository<Order> repository)
    {
        _repository = repository;
    }

    public async Task<ValidationResult> ValidateAsync(Order entity, CancellationToken cancellationToken = default)
    {
        var errors = new List<string>();

        if (!entity.IsValid())
            errors.Add("Order is invalid");

        if (entity.CustomerId <= 0)
            errors.Add("Customer ID must be valid");

        var customerExists = await _repository.CustomerExistsAsync(entity.CustomerId, cancellationToken);
        if (!customerExists)
            errors.Add("Customer does not exist");

        return new ValidationResult { Errors = errors, IsValid = errors.Count == 0 };
    }
}

public class ValidationResult
{
    public bool IsValid { get; set; }
    public List<string> Errors { get; set; } = new();
}
```

---

## Testing Strategies

### Unit Testing Example

```csharp
public class UserOrchestratorTests
{
    [Fact]
    public async Task CreateUser_WithValidUser_ShouldSucceed()
    {
        // Arrange
        var mockRepository = new Mock<IUserRepository<User>>();
        var mockValidator = new Mock<IUserValidator<User>>();
        var mockLogger = new Mock<ILogger<UserOrchestrator<User>>>();

        var orchestrator = new UserOrchestrator<User>(
            mockRepository.Object,
            mockValidator.Object,
            mockLogger.Object);

        var user = new User { Email = "test@example.com" };

        mockValidator
            .Setup(v => v.ValidateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidationResult { IsValid = true });

        // Act
        var result = await orchestrator.CreateUserAsync(user);

        // Assert
        Assert.NotNull(result);
        mockRepository.Verify(r => r.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Once);
    }
}
```

### Integration Testing Example

```csharp
public class UserRepositoryIntegrationTests : IAsyncLifetime
{
    private ApplicationDbContext _context;
    private UserRepository _repository;

    public async Task InitializeAsync()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase("TestDb")
            .Options;

        _context = new ApplicationDbContext(options);
        await _context.Database.EnsureCreatedAsync();

        var logger = new Mock<ILogger<UserRepository>>().Object;
        _repository = new UserRepository(_context, logger);
    }

    public async Task DisposeAsync()
    {
        await _context.DisposeAsync();
    }

    [Fact]
    public async Task AddUser_ShouldPersistToDatabase()
    {
        // Arrange
        var user = new User { Email = "test@example.com" };

        // Act
        await _repository.AddAsync(user);
        var result = await _repository.GetByIdAsync(user.Id);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(user.Email, result.Email);
    }
}
```

---

## Common Patterns & Anti-Patterns

### ? GOOD: Interface-First

```csharp
// Define in Application
public interface IUserService
{
    Task<User> GetUserAsync(int id);
}

// Implement in Infrastructure
public class UserService : IUserService
{
    public async Task<User> GetUserAsync(int id)
    {
        // implementation
    }
}

// Inject interface, not implementation
public class UserController
{
    public UserController(IUserService service) { }
}
```

### ? BAD: Concrete Dependencies

```csharp
// Don't do this!
public class UserController
{
    public UserController(UserService service) { }  // Tightly coupled
}
```

---

### ? GOOD: Thin Controllers

```csharp
[HttpPost]
public async Task<ActionResult> CreateUser(CreateUserRequest request)
{
    var user = new User { Email = request.Email };
    await _orchestrator.CreateUserAsync(user);  // Delegate!
    return Ok();
}
```

### ? BAD: Fat Controllers

```csharp
// Don't do this!
[HttpPost]
public async Task<ActionResult> CreateUser(CreateUserRequest request)
{
    // Validation
    if (string.IsNullOrEmpty(request.Email))
        return BadRequest();

    // Business logic
    var user = new User { Email = request.Email };
    if (user.Email.IsValid())
    {
        // Data access
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
    }

    // Too much responsibility!
    return Ok();
}
```

---

### ? GOOD: Logging Key Points

```csharp
public async Task<Order> CreateOrderAsync(Order order)
{
    _logger.LogInformation("Creating order for customer {CustomerId}", order.CustomerId);
    
    // ... processing ...
    
    _logger.LogInformation("Order created successfully: {OrderId}", order.Id);
    return order;
}
```

### ? BAD: Over-Logging or Under-Logging

```csharp
// Don't do this!
public async Task<Order> CreateOrderAsync(Order order)
{
    _logger.LogInformation("Start");           // Too vague
    _logger.LogInformation("Processing");      // No context
    _logger.LogInformation("Done");            // Not helpful
    // OR
    // No logging at all (hard to debug)
    return order;
}
```

---

### ? GOOD: Async/Await Throughout

```csharp
public async Task<User> GetUserAsync(int id)
{
    return await _repository.GetByIdAsync(id);  // Full async chain
}
```

### ? BAD: Sync Over Async

```csharp
// Don't do this!
public User GetUser(int id)
{
    return _repository.GetByIdAsync(id).Result;  // Blocks thread!
}
```

---

### ? GOOD: Cancellation Token Support

```csharp
public async Task<User> GetUserAsync(int id, CancellationToken cancellationToken = default)
{
    return await _repository.GetByIdAsync(id, cancellationToken);
}
```

### ? BAD: Ignoring Cancellation

```csharp
// Don't do this!
public async Task<User> GetUserAsync(int id)
{
    return await _repository.GetByIdAsync(id);  // No cancellation support
}
```

---

## Summary

The Clean Architecture template enforces:

1. **Strict layer separation** - dependencies point inward only
2. **Interface-first design** - contracts before implementations
3. **Thin entry points** - controllers and middleware coordinate
4. **Generic patterns** - reusable orchestrators and repositories
5. **Specification pattern** - encapsulated query logic
6. **Middleware-first errors** - controllers stay clean
7. **Comprehensive logging** - track execution
8. **Async throughout** - scalable and responsive

This architecture enables:
- ? Easy testing (mock contracts)
- ? Easy extension (implement new contracts)
- ? Easy maintenance (clear responsibilities)
- ? Easy onboarding (consistent patterns)
- ? Production-ready (proven patterns)

---

**See [QUICKSTART.md](QUICKSTART.md) for step-by-step examples, or [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.**

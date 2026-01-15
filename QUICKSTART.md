# Quick Start Guide

Get up and running with the Clean Architecture API Template in 5 minutes.

## Installation

```bash
# Install the template from local path
dotnet new install C:\path\to\ApiTemplate

# Or test first without installing
dotnet new cleanapi \
  --orgName TestOrg \
  --name TestProject \
  --template-source C:\path\to\ApiTemplate
```

## Create a New Project

```bash
# Basic setup with default options
dotnet new cleanapi --orgName MyOrg --name MyApiService
cd MyApiService

# With optional features
dotnet new cleanapi \
  --orgName MyOrg \
  --name MyApiService \
  --testFramework nunit \
  --databaseEngine sqlserver \
  --useSwagger true \
  --useFluentValidation true

# With external dependencies
dotnet new cleanapi \
  --orgName MyOrg \
  --name MyApiService \
  --externalApiClients "Payment,Notification" \
  --databaseEngine postgres
```

## Project Structure Overview

```
src/
??? Core/              # Your domain entities and exceptions
??? Application/       # Orchestrators, interfaces, specifications
??? Services/          # API controllers, middleware, DTOs
??? Infrastructure/    # Repositories, external clients, database
??? Startup/          # Entry point and dependency injection

tests/
??? Unit/             # Unit tests
??? Integration/      # Integration tests
```

## Step 1: Define a Core Entity

Create a new file `src/Core/Entities/Product.cs`:

```csharp
namespace OrgName.solutionName.Core.Entities;

/// <summary>
/// Represents a product in the system.
/// </summary>
public class Product
{
    /// <summary>
    /// Gets or sets the product ID.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Gets or sets the product name.
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the product description.
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the product price.
    /// </summary>
    public decimal Price { get; set; }
}
```

## Step 2: Create an Application Interface

Create `src/Application/Interfaces/IProductRepository.cs`:

```csharp
namespace OrgName.solutionName.Application.Interfaces;

using OrgName.solutionName.Core.Entities;

/// <summary>
/// Repository contract for product data access.
/// </summary>
/// <typeparam name="T">The product entity type.</typeparam>
public interface IProductRepository<T> where T : Product
{
    /// <summary>
    /// Gets a product by ID.
    /// </summary>
    /// <param name="id">The product ID.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The product if found; otherwise null.</returns>
    Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets all products.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Collection of products.</returns>
    Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Adds a new product.
    /// </summary>
    /// <param name="entity">The product to add.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    Task AddAsync(T entity, CancellationToken cancellationToken = default);
}
```

## Step 3: Create a Request DTO

Create `src/Services/DTOs/Requests/CreateProductRequest.cs`:

```csharp
namespace OrgName.solutionName.Services.DTOs.Requests;

/// <summary>
/// Request model for creating a new product.
/// </summary>
public record CreateProductRequest(
    string Name,
    string Description,
    decimal Price);
```

## Step 4: Create an Orchestrator

Create `src/Application/Orchestration/ProductOrchestrator.cs`:

```csharp
namespace OrgName.solutionName.Application.Orchestration;

using Microsoft.Extensions.Logging;
using OrgName.solutionName.Core.Entities;
using OrgName.solutionName.Application.Interfaces;

/// <summary>
/// Orchestrates product business workflows.
/// </summary>
/// <typeparam name="T">The product entity type.</typeparam>
public class ProductOrchestrator<T> where T : Product, new()
{
    private readonly IProductRepository<T> _repository;
    private readonly ILogger<ProductOrchestrator<T>> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="ProductOrchestrator{T}"/> class.
    /// </summary>
    /// <param name="repository">The product repository.</param>
    /// <param name="logger">The logger.</param>
    public ProductOrchestrator(IProductRepository<T> repository, ILogger<ProductOrchestrator<T>> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    /// <summary>
    /// Gets a product by ID.
    /// </summary>
    /// <param name="id">The product ID.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The product if found; otherwise null.</returns>
    public async Task<T?> GetProductAsync(int id, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Retrieving product with ID {ProductId}", id);
        throw new NotImplementedException();
    }

    /// <summary>
    /// Creates a new product.
    /// </summary>
    /// <param name="product">The product to create.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    public async Task CreateProductAsync(T product, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating product: {ProductName}", product.Name);
        throw new NotImplementedException();
    }
}
```

## Step 5: Implement the Repository

Create `src/Infrastructure/Repositories/ProductRepository.cs`:

```csharp
namespace OrgName.solutionName.Infrastructure.Repositories;

using OrgName.solutionName.Core.Entities;
using OrgName.solutionName.Application.Interfaces;

/// <summary>
/// In-memory implementation of product repository for demonstration.
/// </summary>
public class ProductRepository : IProductRepository<Product>
{
    private static readonly List<Product> _products = new();

    /// <inheritdoc />
    public async Task<Product?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    /// <inheritdoc />
    public async Task<IEnumerable<Product>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    /// <inheritdoc />
    public async Task AddAsync(Product entity, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}
```

## Step 6: Create a Controller (Optional)

If you enabled `--useApi true`, create `src/Services/Controllers/ProductsController.cs`:

```csharp
namespace OrgName.solutionName.Services.Controllers;

using OrgName.solutionName.Application.Orchestration;
using OrgName.solutionName.Core.Entities;

/// <summary>
/// API controller for product operations.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ProductOrchestrator<Product> _orchestrator;
    private readonly ILogger<ProductsController> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="ProductsController"/> class.
    /// </summary>
    public ProductsController(ProductOrchestrator<Product> orchestrator, ILogger<ProductsController> logger)
    {
        _orchestrator = orchestrator;
        _logger = logger;
    }

    /// <summary>
    /// Gets a product by ID.
    /// </summary>
    /// <param name="id">The product ID.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The product if found.</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetProduct(int id, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    /// <summary>
    /// Creates a new product.
    /// </summary>
    /// <param name="request">The create request.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The created product.</returns>
    [HttpPost]
    public async Task<ActionResult<Product>> CreateProduct(CreateProductRequest request, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}
```

## Step 7: Register Services in DI

Update `src/Application/DependencyInjection/ApplicationServiceRegistration.cs`:

```csharp
namespace OrgName.solutionName.Application.DependencyInjection;

using Microsoft.Extensions.DependencyInjection;

/// <summary>
/// Registers Application layer services.
/// </summary>
public static class ApplicationServiceRegistration
{
    /// <summary>
    /// Adds Application layer services.
    /// </summary>
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Register orchestrators
        services.AddScoped(typeof(ProductOrchestrator<>));

        // Add FluentValidation if enabled
        // services.AddValidatorsFromAssembly(typeof(ApplicationServiceRegistration).Assembly);

        return services;
    }
}
```

Update `src/Infrastructure/DependencyInjection/InfrastructureServiceRegistration.cs`:

```csharp
namespace OrgName.solutionName.Infrastructure.DependencyInjection;

using Microsoft.Extensions.DependencyInjection;
using OrgName.solutionName.Application.Interfaces;
using OrgName.solutionName.Infrastructure.Repositories;

/// <summary>
/// Registers Infrastructure layer services.
/// </summary>
public static class InfrastructureServiceRegistration
{
    /// <summary>
    /// Adds Infrastructure layer services.
    /// </summary>
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {
        // Register repositories
        services.AddScoped(typeof(IProductRepository<>), typeof(ProductRepository));

        return services;
    }
}
```

## Step 8: Build and Run

```bash
# Restore dependencies
dotnet restore

# Build the solution
dotnet build

# Run the application
dotnet run --project src/Startup/Startup.csproj
```

## Next Steps

? **You've created the foundation!** Now:

1. **Implement the `NotImplementedException()` methods** with your business logic
2. **Add more entities** following the same pattern
3. **Write unit tests** in `tests/Unit/`
4. **Add integration tests** in `tests/Integration/`
5. **Configure your database** in Infrastructure if using `--databaseEngine`

## Tips

- Follow the **interface-first** approach: define contracts before implementing
- Keep **Core layer pure** — no framework references
- **Delegate to orchestrators** from controllers, not services
- Use **middleware** for cross-cutting concerns (logging, validation, error handling)
- Keep **DTOs in Services** and Infrastructure, not Core
- Use `throw new NotImplementedException()` as a guide for what to implement next

## Troubleshooting

**Build errors?** ? Ensure all `using` statements are correct and projects reference each other properly  
**Missing features?** ? Check you used the right `--parameter` flags during template generation  
**DI not working?** ? Verify services are registered in `ApplicationServiceRegistration.cs` and `InfrastructureServiceRegistration.cs`

---

Done! You now have a clean architecture foundation ready for development. See [IMPLEMENTATION.md](IMPLEMENTATION.md) for deeper patterns and best practices.

using Microsoft.Extensions.DependencyInjection;

namespace OrgName.solutionName.Infrastructure.DependencyInjection;

/// <summary>
/// Registers Infrastructure layer services (repositories, external clients, messaging) in the dependency injection container.
/// </summary>
public static class InfrastructureServiceRegistration
{
    /// <summary>
    /// Adds Infrastructure layer services to the dependency injection container.
    /// </summary>
    /// <param name="services">The service collection.</param>
    /// <returns>The service collection for chaining.</returns>
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {
        throw new NotImplementedException();
    }
}
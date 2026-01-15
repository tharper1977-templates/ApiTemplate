using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OrgName.solutionName.Application.DependencyInjection;
using OrgName.solutionName.Infrastructure.DependencyInjection;
using OrgName.solutionName.Services.DependencyInjection;
using OrgName.solutionName.Startup;

namespace OrgName.solutionName.Startup;

/// <summary>
/// Application entry point.
/// </summary>
public class Program
{
    /// <summary>
    /// Main application entry point.
    /// </summary>
    /// <param name="args">Command-line arguments.</param>
    public static void Main(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);

        builder.Services.AddApplicationServices();
        builder.Services.AddInfrastructureServices();
        builder.Services.AddServicesLayer();

        builder.Services.AddHostedService<Worker>();

        var host = builder.Build();
        host.Run();
    }
}
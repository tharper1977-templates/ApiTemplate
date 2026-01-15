using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace OrgName.solutionName.Startup;

/// <summary>
/// Background worker service for long-running tasks.
/// </summary>
public class Worker(ILogger<Worker> logger) : BackgroundService
{
    /// <summary>
    /// Executes the background worker task.
    /// </summary>
    /// <param name="stoppingToken">Cancellation token for graceful shutdown.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        throw new NotImplementedException();
    }
}
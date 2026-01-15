#if UseXUnit
namespace OrgName.solutionName.Tests.Integration;

public class SampleXUnitIntegrationTests : IAsyncLifetime
{
    public Task InitializeAsync()
    {
        throw new NotImplementedException();
    }

    public Task DisposeAsync()
    {
        return Task.CompletedTask;
    }

    [Fact]
    public async Task SampleIntegrationTest_Always_Passes()
    {
        // Arrange
        var expected = true;

        // Act
        var actual = true;

        // Assert
        Assert.Equal(expected, actual);
        await Task.CompletedTask;
    }
}
#endif
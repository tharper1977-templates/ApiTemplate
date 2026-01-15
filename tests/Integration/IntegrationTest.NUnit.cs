#if UseNUnit
namespace OrgName.solutionName.Tests.Integration;

[TestFixture]
public class SampleNUnitIntegrationTests
{
    [OneTimeSetUp]
    public async Task SetUpAsync()
    {
        throw new NotImplementedException();
    }

    [OneTimeTearDown]
    public async Task TearDownAsync()
    {
        await Task.CompletedTask;
    }

    [Test]
    public async Task SampleIntegrationTest_Always_Passes()
    {
        // Arrange
        var expected = true;

        // Act
        var actual = true;

        // Assert
        Assert.That(actual, Is.EqualTo(expected));
        await Task.CompletedTask;
    }
}
#endif
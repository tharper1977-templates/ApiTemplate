#if UseMSTest
namespace OrgName.solutionName.Tests.Integration;

[TestClass]
public class SampleMSTestIntegrationTests
{
    [ClassInitialize]
    public static async Task SetUpAsync(TestContext context)
    {
        throw new NotImplementedException();
    }

    [ClassCleanup]
    public static async Task TearDownAsync()
    {
        await Task.CompletedTask;
    }

    [TestMethod]
    public async Task SampleIntegrationTest_Always_Passes()
    {
        // Arrange
        var expected = true;

        // Act
        var actual = true;

        // Assert
        Assert.AreEqual(expected, actual);
        await Task.CompletedTask;
    }
}
#endif
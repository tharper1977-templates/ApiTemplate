#if UseMSTest
namespace OrgName.solutionName.Tests.Unit;

[TestClass]
public class SampleMSTestTests
{
    [TestInitialize]
    public void Setup()
    {
    }

    [TestMethod]
    public void SampleTest_Always_Passes()
    {
        // Arrange
        var expected = true;

        // Act
        var actual = true;

        // Assert
        Assert.AreEqual(expected, actual);
    }
}
#endif
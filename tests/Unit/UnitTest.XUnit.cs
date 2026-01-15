#if UseXUnit
namespace OrgName.solutionName.Tests.Unit;

public class SampleXUnitTests
{
    [Fact]
    public void SampleTest_Always_Passes()
    {
        // Arrange
        var expected = true;

        // Act
        var actual = true;

        // Assert
        Assert.Equal(expected, actual);
    }
}
#endif
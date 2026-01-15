#if UseNUnit
namespace OrgName.solutionName.Tests.Unit;

[TestFixture]
public class SampleNUnitTests
{
    [SetUp]
    public void Setup()
    {
    }

    [Test]
    public void SampleTest_Always_Passes()
    {
        // Arrange
        var expected = true;

        // Act
        var actual = true;

        // Assert
        Assert.That(actual, Is.EqualTo(expected));
    }
}
#endif
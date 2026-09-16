import CatalogGenerator
import Foundation

/// The `release` executable: it writes one release of the repository
/// (marketplace.md 3.2).
///
/// The run takes four arguments, because the tool reads no state of the host
/// itself: the version, the repository root, the state of the working tree, and
/// the result of the test run. `scripts/release` reads the last two with `git`
/// and with `swift test`, thus a person runs the script and not this
/// executable.
@main
internal enum ReleaseMain {
    /// The exit code of a run that could not make the release.
    private static let failureExitCode: Int32 = 1

    /// The line break that goes after each line of a report.
    private static let lineBreak = "\n"

    /// The number of arguments of a run.
    private static let expectedArgumentCount = 4

    /// The place of each argument in the list.
    private static let versionArgument = 0
    private static let repositoryArgument = 1
    private static let workingTreeArgument = 2
    private static let testRunArgument = 3

    /// What a person reads when the arguments are not the four the run needs.
    private static let usage =
        "usage: release <X.Y.Z> <repository root> <clean|dirty> <passed|failed>"
        + lineBreak
        + "Run scripts/release, which reads the state of the repository for you."

    /// Writes the release, and reports the path of each file it wrote.
    internal static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count == expectedArgumentCount,
            let workingTree = ReleasePreflight.WorkingTree(
                rawValue: arguments[workingTreeArgument]),
            let testRun = ReleasePreflight.TestRun(rawValue: arguments[testRunArgument])
        else {
            fail(withMessage: usage)
        }
        do {
            let report = try Release.run(
                version: arguments[versionArgument],
                repository: URL(fileURLWithPath: arguments[repositoryArgument]),
                preflight: ReleasePreflight(workingTree: workingTree, testRun: testRun))
            let text = report.changedPaths.map { $0 + lineBreak }.joined()
            FileHandle.standardOutput.write(Data(text.utf8))
        } catch {
            fail(withMessage: "release: \(error)")
        }
    }

    /// Reports one message and stops the run.
    ///
    /// - Parameter message: The text to write to the standard error.
    /// - Returns: Nothing: the run stops here.
    private static func fail(withMessage message: String) -> Never {
        FileHandle.standardError.write(Data((message + lineBreak).utf8))
        exit(failureExitCode)
    }
}

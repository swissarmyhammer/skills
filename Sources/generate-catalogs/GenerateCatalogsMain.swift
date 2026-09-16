import CatalogGenerator
import Foundation

/// The `generate-catalogs` executable: it writes the catalogs of the
/// repository from the skill folders (marketplace.md 3.3).
///
/// The run takes one optional argument, the repository root. With no argument
/// it reads the working directory. `scripts/generate-catalogs` gives the root
/// of its own repository, thus a run from any folder writes the same files.
@main
internal enum GenerateCatalogsMain {
    /// The exit code of a run that could not read the repository.
    private static let failureExitCode: Int32 = 1

    /// The line break that goes after the path of each written file.
    private static let lineBreak = "\n"

    /// Writes the catalogs, and reports the path of each file it wrote.
    internal static func main() {
        let root = URL(fileURLWithPath: repositoryRootPath())
        do {
            let files = try CatalogGenerator(repositoryRoot: root).write()
            let report = files.map { $0.path + lineBreak }.joined()
            FileHandle.standardOutput.write(Data(report.utf8))
        } catch {
            FileHandle.standardError.write(Data("generate-catalogs: \(error)\(lineBreak)".utf8))
            exit(failureExitCode)
        }
    }

    /// The repository the run writes: the one argument, or the working
    /// directory.
    ///
    /// - Returns: The path of the repository root.
    private static func repositoryRootPath() -> String {
        CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath
    }
}

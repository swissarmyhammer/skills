@testable import CatalogGenerator
import Foundation
import Testing

/// Holds the release tool to its contract (marketplace.md 3.2): one command
/// writes the new version into each file that publishes it, and the tool
/// refuses a release that would name a tree nobody can trust.
///
/// A release tool that can tag a broken tree is worse than no release tool,
/// because the tag then names bytes that fail. Thus each refusal has a test,
/// and each refusal test holds every file of the fixture repository byte for
/// byte.
@Suite("Release tool")
struct ReleaseToolTests {
    /// The version that a release test writes. It is not the version of the
    /// fixture repository, thus a value that the tool did not write fails.
    private static let nextVersion = "1.0.1"

    /// A version with two parts, which is not a semantic version.
    private static let versionWithTwoParts = "1.0"

    /// A repository that a person can release: the tree is clean and the tests
    /// passed.
    private static let releasableState = ReleasePreflight(workingTree: .clean, testRun: .passed)

    /// The path of the script that makes the release commit and the release
    /// tag, relative to the repository root.
    private static let releaseCommitScriptPath = "scripts/release-commit"

    /// The name of the `git` program, which only this test target starts.
    private static let gitProgramName = "git"

    /// The folder that holds `git` and `sh` on a macOS system.
    private static let programFolder = "/usr/bin"

    /// The exit status of a run that did what it was asked to do.
    private static let successExitStatus: Int32 = 0

    /// The text that the release commit of version ``nextVersion`` holds as its
    /// subject.
    private static let expectedCommitSubject = "release: v\(nextVersion)"

    /// The name of the tag that a release of version ``nextVersion`` makes.
    private static let expectedTagName = "v\(nextVersion)"

    /// The name of the tag that a release of the version the fixture already
    /// names makes.
    private static let expectedFixtureTagName = "v\(FixtureRepository.version)"

    /// The script that makes the release commit and the release tag.
    private static var releaseCommitScript: URL {
        RepositoryLayout.repositoryRoot().appendingPathComponent(releaseCommitScriptPath)
    }

    /// Builds a fixture repository whose catalogs are current.
    ///
    /// - Returns: The root of the new repository.
    /// - Throws: An error when a file cannot be written.
    private static func makeReleasableRepository() throws -> URL {
        let root = try FixtureRepository.make()
        try CatalogGenerator(repositoryRoot: root).write()
        return root
    }

    /// The `SKILL.md` file of one skill of a fixture repository.
    ///
    /// - Parameters:
    ///   - name: The name of the skill.
    ///   - root: The root of the repository.
    /// - Returns: The file URL.
    private static func skillFile(named name: String, inRepositoryAt root: URL) -> URL {
        root
            .appendingPathComponent(FixtureRepository.skillsFolderName, isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
            .appendingPathComponent(FixtureRepository.skillFileName)
    }

    /// Decodes one catalog of a fixture repository.
    ///
    /// - Parameters:
    ///   - path: The path of the file, relative to the repository root.
    ///   - model: The model to decode.
    ///   - root: The root of the repository.
    /// - Returns: The decoded value.
    /// - Throws: An error when the file cannot be read, or cannot be decoded.
    private static func catalog<Model: Decodable>(
        atPath path: String, as model: Model.Type, inRepositoryAt root: URL
    ) throws -> Model {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        return try JSONDecoder().decode(model, from: data)
    }

    /// Holds a release that must be refused, and holds the repository equal
    /// before and after the run.
    ///
    /// - Parameters:
    ///   - version: The version that the run asks for.
    ///   - preflight: The state of the repository that the run reads.
    ///   - error: The refusal that the run must report.
    ///   - prepare: A step that runs over the fixture repository before the
    ///     release, for a test that needs a repository in another state.
    /// - Throws: An error when the fixture cannot be written or read.
    private static func expectRefusal(
        version: String = nextVersion,
        preflight: ReleasePreflight = releasableState,
        error: ReleaseError,
        prepare: (URL) throws -> Void = { _ in }
    ) throws {
        let root = try makeReleasableRepository()
        defer { try? FileManager.default.removeItem(at: root) }
        try prepare(root)
        let before = try FixtureRepository.everyFile(inRepositoryAt: root)
        #expect(throws: error) {
            try Release.run(version: version, repository: root, preflight: preflight)
        }
        let after = try FixtureRepository.everyFile(inRepositoryAt: root)
        #expect(before == after)
    }

    /// Runs one program and waits for it.
    ///
    /// Only this test target starts a program: the release tool itself never
    /// starts one, because the git steps of a release are shell scripts.
    ///
    /// - Parameters:
    ///   - path: The path of the program.
    ///   - arguments: The arguments of the run.
    ///   - folder: The working folder of the run.
    /// - Returns: The exit status and the text of the standard output.
    /// - Throws: An error when the program cannot start.
    @discardableResult
    private static func run(
        _ path: String, arguments: [String], inFolder folder: URL
    ) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.currentDirectoryURL = folder
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (process.terminationStatus, output)
    }

    /// Runs one `git` command in a fixture repository.
    ///
    /// - Parameters:
    ///   - arguments: The arguments of the command.
    ///   - root: The root of the repository.
    /// - Returns: The text of the standard output.
    /// - Throws: An error when `git` cannot start.
    @discardableResult
    private static func git(_ arguments: [String], inRepositoryAt root: URL) throws -> String {
        let result = try run(
            "\(programFolder)/\(gitProgramName)", arguments: arguments, inFolder: root)
        #expect(result.status == successExitStatus, "git \(arguments.joined(separator: " ")) failed.")
        return result.output
    }

    /// Makes a git repository of a fixture folder, with one commit that holds
    /// each file of the fixture.
    ///
    /// - Parameter root: The root of the repository.
    /// - Throws: An error when `git` cannot start.
    private static func makeGitRepository(at root: URL) throws {
        try git(["init", "--quiet"], inRepositoryAt: root)
        try git(["config", "user.email", "fixture@example.com"], inRepositoryAt: root)
        try git(["config", "user.name", "Fixture"], inRepositoryAt: root)
        try git(["config", "commit.gpgsign", "false"], inRepositoryAt: root)
        try git(["add", "--all"], inRepositoryAt: root)
        try git(["commit", "--quiet", "--message", "test: the fixture library"], inRepositoryAt: root)
    }

    /// A release writes the new version into the `VERSION` file, into each
    /// `SKILL.md`, and into each catalog.
    @Test("A release writes the new version into every file that publishes it")
    func releaseWritesTheVersionEverywhere() throws {
        let root = try Self.makeReleasableRepository()
        defer { try? FileManager.default.removeItem(at: root) }
        let report = try Release.run(
            version: Self.nextVersion, repository: root, preflight: Self.releasableState)
        #expect(report.version == Self.nextVersion)
        let versionText = try String(
            contentsOf: root.appendingPathComponent(FixtureRepository.versionFileName),
            encoding: .utf8)
        #expect(versionText.trimmingCharacters(in: .whitespacesAndNewlines) == Self.nextVersion)
        for name in FixtureRepository.skillNames {
            let file = Self.skillFile(named: name, inRepositoryAt: root)
            let skillVersion = try SkillFileVersion.version(ofSkillAt: file)
            #expect(skillVersion == Self.nextVersion)
        }
        let catalog = try Self.catalog(
            atPath: CommittedClaudeCatalog.path, as: CommittedClaudeCatalog.self,
            inRepositoryAt: root)
        #expect(catalog.metadata.version == Self.nextVersion)
        let manifest = try Self.catalog(
            atPath: CommittedCodexPluginManifest.path, as: CommittedCodexPluginManifest.self,
            inRepositoryAt: root)
        #expect(manifest.version == Self.nextVersion)
    }

    /// The report of a release names each file that the run wrote.
    @Test("The report of a release names the version file and each catalog")
    func releaseReportsEveryFileItWrote() throws {
        let root = try Self.makeReleasableRepository()
        defer { try? FileManager.default.removeItem(at: root) }
        let report = try Release.run(
            version: Self.nextVersion, repository: root, preflight: Self.releasableState)
        #expect(report.changedPaths.contains(FixtureRepository.versionFileName))
        #expect(report.changedPaths.contains(CommittedClaudeCatalog.path))
        #expect(report.changedPaths.contains(CommittedCodexPluginManifest.path))
        for name in FixtureRepository.skillNames {
            let path =
                "\(FixtureRepository.skillsFolderName)/\(name)/\(FixtureRepository.skillFileName)"
            #expect(report.changedPaths.contains(path))
        }
    }

    /// A version that is not a semantic version stops the run, and the run
    /// writes nothing.
    @Test("A version that is not X.Y.Z is refused, and nothing is written")
    func aVersionWithTwoPartsIsRefused() throws {
        try Self.expectRefusal(
            version: Self.versionWithTwoParts,
            error: .versionIsNotSemantic(Self.versionWithTwoParts))
    }

    /// A dirty working tree stops the run, and the run writes nothing.
    ///
    /// A release of a dirty tree would commit the work of somebody else under a
    /// release subject, and would tag bytes that no test ever read.
    @Test("A dirty working tree is refused, and nothing is written")
    func aDirtyWorkingTreeIsRefused() throws {
        try Self.expectRefusal(
            preflight: ReleasePreflight(workingTree: .dirty, testRun: .passed),
            error: .workingTreeIsDirty)
    }

    /// Catalogs that are not the output of the generator stop the run, and the
    /// run writes nothing.
    ///
    /// A committed catalog that is stale says that somebody changed the library
    /// and did not run the generator. A release would fold that drift into a
    /// release commit, thus the tool stops and names each stale file.
    @Test("Stale catalogs are refused, and nothing is written")
    func staleCatalogsAreRefused() throws {
        try Self.expectRefusal(
            error: .catalogsAreStale([CommittedDiscoveryIndex.path])
        ) { root in
            let file = Self.skillFile(named: FixtureRepository.skillNames[0], inRepositoryAt: root)
            let text = try String(contentsOf: file, encoding: .utf8)
            try Data((text + "\n\nOne more line, which changes the digest.\n").utf8)
                .write(to: file)
        }
    }

    /// Red tests stop the run, and the run writes nothing.
    @Test("A red test run is refused, and nothing is written")
    func aRedTestRunIsRefused() throws {
        try Self.expectRefusal(
            preflight: ReleasePreflight(workingTree: .clean, testRun: .failed),
            error: .testsAreRed)
    }

    /// The release commit script makes the release commit and the release tag.
    ///
    /// The git steps of a release are a shell script, because no Swift code of
    /// this repository starts `git`. Thus the test runs the script itself.
    @Test("The release commit script makes the release commit and the tag")
    func releaseCommitScriptMakesTheCommitAndTheTag() throws {
        let root = try Self.makeReleasableRepository()
        defer { try? FileManager.default.removeItem(at: root) }
        try Self.makeGitRepository(at: root)
        _ = try Release.run(
            version: Self.nextVersion, repository: root, preflight: Self.releasableState)
        let result = try Self.run(
            Self.releaseCommitScript.path, arguments: [Self.nextVersion, root.path],
            inFolder: root)
        #expect(result.status == Self.successExitStatus)
        let tags = try Self.git(["tag", "--list"], inRepositoryAt: root)
        #expect(tags == Self.expectedTagName)
        let subject = try Self.git(["log", "-1", "--pretty=%s"], inRepositoryAt: root)
        #expect(subject == Self.expectedCommitSubject)
        let status = try Self.git(["status", "--porcelain"], inRepositoryAt: root)
        #expect(status.isEmpty)
    }

    /// The release commit script makes the tag when the files already name the
    /// version.
    ///
    /// This is the first release of a repository: the files name the version
    /// before the tool runs, thus the release adds no change, and the tag alone
    /// marks the release. A script that asks git for a commit with nothing in
    /// it would stop here, and the release would have no tag.
    @Test("The release commit script makes the tag when no file changed")
    func releaseCommitScriptMakesTheTagWithNoChange() throws {
        let root = try Self.makeReleasableRepository()
        defer { try? FileManager.default.removeItem(at: root) }
        try Self.makeGitRepository(at: root)
        let head = try Self.git(["rev-parse", "HEAD"], inRepositoryAt: root)
        let result = try Self.run(
            Self.releaseCommitScript.path, arguments: [FixtureRepository.version, root.path],
            inFolder: root)
        #expect(result.status == Self.successExitStatus)
        let tags = try Self.git(["tag", "--list"], inRepositoryAt: root)
        #expect(tags == Self.expectedFixtureTagName)
        let headAfter = try Self.git(["rev-parse", "HEAD"], inRepositoryAt: root)
        #expect(headAfter == head)
    }
}

@testable import CatalogGenerator
import Foundation
import Testing

/// Holds the one release version of the repository equal in each place that
/// publishes it (marketplace.md 3.2 and 3.6 step 4).
///
/// The `VERSION` file is the one source of the version. The `metadata.version`
/// line of each `SKILL.md`, the version of each catalog, and the name of the
/// release tag repeat it. A difference between any two of them gives a user a
/// skill that names one version and a catalog that names another.
@Suite("Version")
struct VersionTests {
    /// The `SKILL.md` text that the rewrite test reads.
    ///
    /// The text holds a `version:` key at the top of the frontmatter and the
    /// word `version` in the body, thus a rewrite that changes more than the
    /// metadata line fails here.
    private static let sampleSkillFile = """
        ---
        name: sample
        description: A sample skill.
        version: 0.0.1
        metadata:
          author: fixture
          version: "1.0.0"
        ---

        # Sample

        The body says version: "1.0.0", and the rewrite keeps it.
        """

    /// The same text after a rewrite to ``rewrittenVersion``.
    private static let rewrittenSkillFile = """
        ---
        name: sample
        description: A sample skill.
        version: 0.0.1
        metadata:
          author: fixture
          version: "2.3.4"
        ---

        # Sample

        The body says version: "1.0.0", and the rewrite keeps it.
        """

    /// The version that the rewrite test writes.
    private static let rewrittenVersion = "2.3.4"

    /// A `SKILL.md` text with no metadata block, thus no version to rewrite.
    private static let skillFileWithNoMetadata = """
        ---
        name: sample
        description: A sample skill.
        ---

        # Sample
        """

    /// The name of the environment value that names the kind of the reference
    /// of a CI run.
    private static let referenceKindName = "GITHUB_REF_TYPE"

    /// The name of the environment value that names the reference of a CI run.
    private static let referenceName = "GITHUB_REF_NAME"

    /// The value of ``referenceKindName`` for a run that is for a tag.
    private static let tagReferenceKind = "tag"

    /// The release version of the repository, from the one source of it.
    ///
    /// - Returns: The version, with no leading and no trailing space.
    /// - Throws: An error when the version file cannot be read.
    private static func releaseVersion() throws -> String {
        let url = RepositoryLayout.repositoryRoot()
            .appendingPathComponent(CatalogGenerator.versionFileName)
        let text = try String(contentsOf: url, encoding: .utf8)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The `SKILL.md` file of each skill of the checked-in library.
    ///
    /// - Returns: The files, one for each direct child of the layer root that
    ///   holds a `SKILL.md` file.
    /// - Throws: An error when the layer root cannot be read.
    private static func skillFiles() throws -> [URL] {
        let root = RepositoryLayout.skillsRoot()
        let children = try FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil)
        return
            children
            .map { $0.appendingPathComponent(FixtureRepository.skillFileName) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .sorted { $0.path < $1.path }
    }

    /// Every skill of the library names the release version of the repository.
    ///
    /// The release tool writes each line from the same value, thus a difference
    /// here says that somebody edited one file by hand.
    @Test("Every SKILL.md names the release version of the repository")
    func everySkillNamesTheReleaseVersion() throws {
        let version = try Self.releaseVersion()
        let files = try Self.skillFiles()
        #expect(!files.isEmpty)
        for file in files {
            let skillVersion = try SkillFileVersion.version(ofSkillAt: file)
            #expect(skillVersion == version, "\(file.path) does not name \(version).")
        }
    }

    /// The rewrite changes the metadata version line and no other byte.
    @Test("The rewrite changes only the metadata version line")
    func rewriteChangesOnlyTheMetadataVersionLine() throws {
        let rewritten = SkillVersionRewrite.rewritten(
            text: Self.sampleSkillFile, version: Self.rewrittenVersion)
        #expect(rewritten == Self.rewrittenSkillFile)
    }

    /// The rewrite reports a file that holds no metadata version line, thus the
    /// release tool can name the file instead of writing a file with no
    /// version.
    @Test("The rewrite reports a file with no metadata version line")
    func rewriteReportsAFileWithNoMetadataVersion() {
        let rewritten = SkillVersionRewrite.rewritten(
            text: Self.skillFileWithNoMetadata, version: Self.rewrittenVersion)
        #expect(rewritten == nil)
    }

    /// A CI run for a `v*` tag names the release version of the tag.
    @Test("A run for a v tag names the version of the tag")
    func tagRunNamesTheVersionOfTheTag() {
        let version = ReleaseTag.version(
            inEnvironment: [
                Self.referenceKindName: Self.tagReferenceKind,
                Self.referenceName: "v1.2.3",
            ])
        #expect(version == "1.2.3")
    }

    /// A CI run for a branch names no release version.
    @Test("A run for a branch names no release version")
    func branchRunNamesNoVersion() {
        let version = ReleaseTag.version(
            inEnvironment: [
                Self.referenceKindName: "branch",
                Self.referenceName: "main",
            ])
        #expect(version == nil)
    }

    /// A tag that does not open with `v` is not a release tag.
    @Test("A tag with no v prefix names no release version")
    func tagWithNoPrefixNamesNoVersion() {
        let version = ReleaseTag.version(
            inEnvironment: [
                Self.referenceKindName: Self.tagReferenceKind,
                Self.referenceName: "1.2.3",
            ])
        #expect(version == nil)
    }

    /// When this run is for a `v*` tag, the tag names the release version of
    /// the repository and the version of the Claude catalog (marketplace.md 3.6
    /// step 4).
    ///
    /// On any other run there is no tag, and the test holds nothing. Thus the
    /// suite needs no gate: the run that publishes a release is the run that
    /// checks the tag.
    @Test("A tag run names the version of the repository and of the catalog")
    func theTagOfThisRunNamesTheReleaseVersion() throws {
        let tagged = ReleaseTag.version(inEnvironment: ProcessInfo.processInfo.environment)
        let version = try Self.releaseVersion()
        let catalogData = try Data(
            contentsOf: RepositoryLayout.repositoryRoot()
                .appendingPathComponent(CommittedClaudeCatalog.path))
        let catalog = try JSONDecoder().decode(CommittedClaudeCatalog.self, from: catalogData)
        #expect(tagged == nil || tagged == version)
        #expect(tagged == nil || tagged == catalog.metadata.version)
    }
}

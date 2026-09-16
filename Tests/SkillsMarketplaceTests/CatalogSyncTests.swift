@testable import CatalogGenerator
import CryptoKit
import Foundation
import Testing

/// Holds the committed catalogs equal to the bytes that ``CatalogGenerator``
/// writes from the skill folders (marketplace.md 3.3 and 3.6 step 3).
///
/// The catalogs are generated, thus nobody edits them by hand. A skill that is
/// added, dropped, or renamed without a run of `scripts/generate-catalogs`
/// fails this suite, and thus fails CI, instead of reaching a user as a catalog
/// that does not name the skill.
///
/// A comparison with the generator output finds drift, but it cannot find a
/// wrong value: a changed value passes after one run of the generator. Thus
/// each published value also has a test that holds it equal to a literal
/// written here, which is a truth outside the generator.
@Suite("Catalog sync")
struct CatalogSyncTests {
    /// The name of the file of a skill. A folder of the layer root is a skill
    /// when it holds this file.
    private static let skillFileName = "SKILL.md"

    /// The opening text of the `digest` of a discovery index entry.
    private static let digestPrefix = "sha256:"

    /// The format of one byte of a digest: two lower-case hexadecimal digits.
    private static let digestByteFormat = "%02x"

    /// The one plugin that each catalog holds (marketplace.md 3.3).
    private static let expectedPluginCount = 1

    /// The name of this marketplace, which each catalog repeats.
    private static let expectedMarketplaceName = "swissarmyhammer-skills"

    /// The owner of this marketplace.
    private static let expectedOwnerName = "swissarmyhammer"

    /// The name of the one plugin of this marketplace.
    private static let expectedPluginName = "swissarmyhammer"

    /// The folder of the files of the plugin: the repository root itself.
    private static let expectedPluginSource = "./"

    /// Whether the plugin needs a `plugin.json` file. It does not, because it
    /// lists its skills itself.
    private static let expectedPluginIsStrict = false

    /// The kind of a plugin source that names a folder of this repository.
    ///
    /// A client takes any other kind as a remote source, and it then skips the
    /// plugin. Thus a changed kind would drop every skill of this marketplace
    /// with no message to a user.
    private static let expectedLocalSourceKind = "local"

    /// The name of the one layer root of this marketplace.
    private static let skillsFolderName = "skills"

    /// The folder that holds the skills of the plugin, as the Codex plugin
    /// manifest writes it.
    private static let expectedSkillsFolder = "./\(skillsFolderName)"

    /// The form of an artifact that is one `SKILL.md` file.
    private static let expectedSkillFileType = "skill-md"

    /// The path of each published catalog file, in the order the generator
    /// writes them.
    ///
    /// The path is the most published value of a catalog, because a client
    /// finds the file by that name. Thus each path is a literal of the test
    /// target, and a changed path in the generator fails this suite instead of
    /// leaving a user with a file no client reads.
    private static let expectedGeneratedPaths = [
        CommittedClaudeCatalog.path,
        CommittedCodexCatalog.path,
        CommittedCodexPluginManifest.path,
        CommittedDiscoveryIndex.path,
    ]

    /// The path of one skill folder, as the Claude catalog writes it.
    ///
    /// - Parameter name: The name of the skill.
    /// - Returns: The path, relative to the source of the plugin.
    private static func pluginSkillPath(name: String) -> String {
        "\(expectedSkillsFolder)/\(name)"
    }

    /// The URL of the `SKILL.md` of one skill, as the discovery index writes
    /// it.
    ///
    /// - Parameter name: The name of the skill.
    /// - Returns: The URL, relative to the root of the site.
    private static func indexSkillURL(name: String) -> String {
        "/\(skillsFolderName)/\(name)/\(skillFileName)"
    }

    /// The files that the generator writes from the checked-in skill folders.
    ///
    /// - Returns: One entry for each generated file.
    /// - Throws: An error when the generator cannot read the repository.
    private static func generatedFiles() throws -> [GeneratedCatalogFile] {
        try CatalogGenerator(repositoryRoot: RepositoryLayout.repositoryRoot()).generate()
    }

    /// Reads one committed file of the repository.
    ///
    /// - Parameter path: The path of the file, relative to the repository root.
    /// - Returns: The bytes of the file.
    /// - Throws: An error when the file is not there, or cannot be read.
    private static func committedFile(atPath path: String) throws -> Data {
        try Data(contentsOf: RepositoryLayout.repositoryRoot().appendingPathComponent(path))
    }

    /// Decodes one committed file into the model of this test target.
    ///
    /// - Parameters:
    ///   - path: The path of the file, relative to the repository root.
    ///   - model: The model to decode.
    /// - Returns: The decoded value.
    /// - Throws: An error when the file cannot be read, or cannot be decoded.
    private static func committedCatalog<Model: Decodable>(
        atPath path: String, as model: Model.Type
    ) throws -> Model {
        try JSONDecoder().decode(model, from: committedFile(atPath: path))
    }

    /// The release version of the repository, from the one source of it.
    ///
    /// - Returns: The version, with no leading and no trailing space.
    /// - Throws: An error when the version file cannot be read.
    private static func releaseVersion() throws -> String {
        let text = try String(
            decoding: committedFile(atPath: CatalogGenerator.versionFileName), as: UTF8.self)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The names of the skill folders on disk, which is the truth that every
    /// catalog reports.
    ///
    /// The walk keeps a direct child of the layer root that holds a `SKILL.md`
    /// file, thus it skips `_partials/` in the same way discovery skips it.
    ///
    /// - Returns: The names, in sorted order.
    /// - Throws: An error when the layer root cannot be read.
    private static func skillFolderNames() throws -> [String] {
        let root = RepositoryLayout.skillsRoot()
        let children = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        return
            children
            .filter { FileManager.default.fileExists(atPath: $0.appendingPathComponent(skillFileName).path) }
            .map(\.lastPathComponent)
            .sorted()
    }

    /// The `sha256:` digest of one file, computed here rather than taken from
    /// the generator.
    ///
    /// - Parameter url: The file to read.
    /// - Returns: The digest, in the form the discovery index writes.
    /// - Throws: An error when the file cannot be read.
    private static func digest(ofFileAt url: URL) throws -> String {
        let bytes = try Data(contentsOf: url)
        let hexadecimal = SHA256.hash(data: bytes).map { String(format: digestByteFormat, $0) }.joined()
        return digestPrefix + hexadecimal
    }

    /// Every committed catalog file holds the bytes that the generator writes
    /// now.
    ///
    /// A missing file also fails here, because the read of the committed file
    /// throws.
    @Test("Every committed catalog file holds the generated bytes")
    func committedCatalogsAreCurrent() throws {
        for file in try Self.generatedFiles() {
            let committed = try Self.committedFile(atPath: file.path)
            #expect(
                committed == file.contents,
                "\(file.path) is not the same as the generator output. Run scripts/generate-catalogs.")
        }
    }

    /// The generator writes each catalog to the path a client reads.
    ///
    /// A comparison with the generator output cannot find a wrong path: a
    /// changed path passes after one run of the generator, while the file a
    /// client opens keeps its old bytes. Thus the paths are literals here.
    @Test("The generator writes each catalog to its published path")
    func generatedPathsArePublishedPaths() throws {
        let paths = try Self.generatedFiles().map(\.path)
        #expect(paths == Self.expectedGeneratedPaths)
    }

    /// The generator writes the same bytes on disk each time it runs.
    ///
    /// The test writes a fixture repository two times and reads each file back,
    /// thus a value that is not stable from run to run fails here. A comparison
    /// of two return values of `generate()` could not fail, because the keys are
    /// sorted and the skills are in name order by construction.
    @Test("The generator writes the same files on a second run")
    func generationIsDeterministic() throws {
        let root = try FixtureRepository.make()
        defer { try? FileManager.default.removeItem(at: root) }
        let generator = CatalogGenerator(repositoryRoot: root)
        let firstPaths = try generator.write().map(\.path)
        let first = try FixtureRepository.filesOnDisk(atPaths: firstPaths, inRepositoryAt: root)
        let secondPaths = try generator.write().map(\.path)
        let second = try FixtureRepository.filesOnDisk(atPaths: secondPaths, inRepositoryAt: root)
        #expect(firstPaths == secondPaths)
        #expect(first == second)
    }

    /// The Claude catalog names this marketplace and its one plugin.
    @Test("The Claude catalog names the marketplace and its local plugin")
    func claudeCatalogNamesTheMarketplace() throws {
        let catalog = try Self.committedCatalog(
            atPath: CommittedClaudeCatalog.path, as: CommittedClaudeCatalog.self)
        #expect(catalog.name == Self.expectedMarketplaceName)
        #expect(catalog.owner.name == Self.expectedOwnerName)
        #expect(catalog.plugins.count == Self.expectedPluginCount)
        let plugin = try #require(catalog.plugins.first)
        #expect(plugin.name == Self.expectedPluginName)
        #expect(plugin.source == Self.expectedPluginSource)
        #expect(plugin.strict == Self.expectedPluginIsStrict)
    }

    /// The one plugin of the Claude catalog lists every skill folder one time.
    @Test("The Claude plugin lists every skill folder exactly once")
    func claudePluginListsEverySkillOnce() throws {
        let catalog = try Self.committedCatalog(
            atPath: CommittedClaudeCatalog.path, as: CommittedClaudeCatalog.self)
        #expect(catalog.plugins.count == Self.expectedPluginCount)
        let plugin = try #require(catalog.plugins.first)
        let expected = try Self.skillFolderNames().map(Self.pluginSkillPath)
        #expect(plugin.skills == expected)
        #expect(Set(plugin.skills).count == plugin.skills.count)
    }

    /// The Codex catalog holds one plugin with a `local` source at the
    /// repository root.
    ///
    /// A client takes a source of any other kind as a remote source, and it
    /// then skips the plugin. Thus a wrong kind, or a wrong path, would give a
    /// user a marketplace with no skill in it.
    @Test("The Codex catalog holds one local plugin at the repository root")
    func codexCatalogHoldsOneLocalPlugin() throws {
        let catalog = try Self.committedCatalog(
            atPath: CommittedCodexCatalog.path, as: CommittedCodexCatalog.self)
        #expect(catalog.name == Self.expectedMarketplaceName)
        #expect(catalog.plugins.count == Self.expectedPluginCount)
        let plugin = try #require(catalog.plugins.first)
        #expect(plugin.name == Self.expectedPluginName)
        #expect(plugin.source.kind == Self.expectedLocalSourceKind)
        #expect(plugin.source.path == Self.expectedPluginSource)
    }

    /// The Codex plugin manifest names the plugin, the skills folder, and the
    /// release version.
    ///
    /// The skills folder is the one layer root of this repository. A wrong
    /// folder would give a reader no skill at all.
    @Test("The Codex plugin manifest names the skills folder and the version")
    func codexPluginManifestNamesTheSkillsFolder() throws {
        let manifest = try Self.committedCatalog(
            atPath: CommittedCodexPluginManifest.path, as: CommittedCodexPluginManifest.self)
        let version = try Self.releaseVersion()
        #expect(manifest.name == Self.expectedPluginName)
        #expect(manifest.skills == Self.expectedSkillsFolder)
        #expect(manifest.version == version)
    }

    /// The discovery index names every skill folder, and each entry carries the
    /// URL and the digest of its own `SKILL.md`.
    @Test("Each discovery index entry carries the digest of its SKILL.md")
    func indexDigestsMatchTheSkillFiles() throws {
        let index = try Self.committedCatalog(
            atPath: CommittedDiscoveryIndex.path, as: CommittedDiscoveryIndex.self)
        let names = try Self.skillFolderNames()
        #expect(index.skills.map(\.name) == names)
        for entry in index.skills {
            let file = RepositoryLayout.skillsRoot()
                .appendingPathComponent(entry.name)
                .appendingPathComponent(Self.skillFileName)
            let digest = try Self.digest(ofFileAt: file)
            #expect(entry.type == Self.expectedSkillFileType)
            #expect(entry.url == Self.indexSkillURL(name: entry.name))
            #expect(entry.digest == digest)
        }
    }

    /// The release version of the Claude catalog is the `VERSION` file, which
    /// is the one source of the version.
    @Test("The Claude catalog version is the VERSION file")
    func catalogVersionIsTheVersionFile() throws {
        let catalog = try Self.committedCatalog(
            atPath: CommittedClaudeCatalog.path, as: CommittedClaudeCatalog.self)
        let version = try Self.releaseVersion()
        #expect(catalog.metadata.version == version)
    }
}

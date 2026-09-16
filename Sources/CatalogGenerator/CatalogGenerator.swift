import Foundation
import FoundationModelsSkills

/// Writes the catalogs of the marketplace from the skill folders
/// (marketplace.md 3.3 and 3.6 step 3).
///
/// The generator reads the library with a `SkillsRegistry` over `skills/`,
/// which is the loader the client itself uses. Thus a catalog names the skills
/// the client loads, with the description the client reads, and a hand-written
/// list can never drift away from the folders.
///
/// The output is deterministic: the keys are sorted, the skills are in name
/// order, and each file ends with a line break. Thus a second run writes the
/// same bytes, and a difference in the working tree is a difference of the
/// library.
public struct CatalogGenerator: Sendable {
    /// The name of the file that holds the release version of the catalogs. It
    /// is the one source of the version.
    public static let versionFileName = "VERSION"

    /// The line break that ends each generated file.
    private static let lineBreak = "\n"

    /// The root of the repository that the generator reads and writes.
    public let repositoryRoot: URL

    /// Makes a generator over one repository.
    ///
    /// - Parameter repositoryRoot: The root of the repository that holds the
    ///   `VERSION` file and the `skills/` layer root.
    public init(repositoryRoot: URL) {
        self.repositoryRoot = repositoryRoot
    }

    /// Builds the bytes of each catalog file from the skill folders.
    ///
    /// - Returns: One entry for each file, in write order.
    /// - Throws: A ``CatalogGeneratorError`` when the generator cannot read the
    ///   version file, the layer root, or a `SKILL.md` file.
    public func generate() throws -> [GeneratedCatalogFile] {
        let version = try releaseVersion()
        let skills = try catalogSkills()
        return try [
            file(atPath: ClaudeCatalog.path, holding: ClaudeCatalog(version: version, skills: skills)),
            file(atPath: CodexCatalog.path, holding: CodexCatalog()),
            file(atPath: CodexPluginManifest.path, holding: CodexPluginManifest(version: version)),
            file(atPath: DiscoveryIndex.path, holding: DiscoveryIndex(skills: skills)),
        ]
    }

    /// Writes each catalog file into the repository, and makes the folder of a
    /// file that is not there yet.
    ///
    /// - Returns: The files that the run wrote, in write order.
    /// - Throws: A ``CatalogGeneratorError`` when the generator cannot read the
    ///   repository, or the error of a write.
    @discardableResult
    public func write() throws -> [GeneratedCatalogFile] {
        let files = try generate()
        for file in files {
            let url = repositoryRoot.appendingPathComponent(file.path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.contents.write(to: url, options: .atomic)
        }
        return files
    }

    /// Encodes one catalog into the bytes of its file.
    ///
    /// - Parameters:
    ///   - path: The path of the file, relative to the repository root.
    ///   - catalog: The catalog to encode.
    /// - Returns: The file, with its bytes.
    /// - Throws: The error of the encoder.
    private func file(atPath path: String, holding catalog: some Encodable) throws -> GeneratedCatalogFile {
        GeneratedCatalogFile(path: path, contents: try Self.encoded(catalog))
    }

    /// Encodes one value as deterministic JSON.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: The bytes, with sorted keys and a line break at the end.
    /// - Throws: The error of the encoder.
    private static func encoded(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value) + Data(lineBreak.utf8)
    }

    /// Reads the release version of the catalogs.
    ///
    /// - Returns: The version, with no leading and no trailing space.
    /// - Throws: A ``CatalogGeneratorError`` when the file cannot be read, or
    ///   holds no version.
    private func releaseVersion() throws -> String {
        let url = repositoryRoot.appendingPathComponent(Self.versionFileName)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw CatalogGeneratorError.unreadableVersion(url)
        }
        let version = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !version.isEmpty else {
            throw CatalogGeneratorError.emptyVersion(url)
        }
        return version
    }

    /// Reads the skills of the library with the loader of the client.
    ///
    /// `SkillsRegistry.metadata()` reads `skills/<name>/SKILL.md` and sorts its
    /// rows by name, thus it gives the folders in the order the catalogs write
    /// them, and it skips `_partials/`, which holds no `SKILL.md` file.
    ///
    /// - Returns: The skills, in name order.
    /// - Throws: A ``CatalogGeneratorError`` when the layer root holds no
    ///   skill, or a `SKILL.md` file cannot be read.
    private func catalogSkills() throws -> [CatalogSkill] {
        let root = repositoryRoot.appendingPathComponent(
            MarketplaceIdentity.skillsFolderName, isDirectory: true)
        let metadata = SkillsRegistry(roots: [root]).metadata().sorted { $0.id < $1.id }
        guard !metadata.isEmpty else {
            throw CatalogGeneratorError.emptyLibrary(root)
        }
        return try metadata.map {
            try catalogSkill(name: $0.id, description: $0.description, inLayerRoot: root)
        }
    }

    /// Reads the `SKILL.md` file of one skill and takes its digest.
    ///
    /// - Parameters:
    ///   - name: The name of the skill, which is the name of its folder.
    ///   - description: The description of the skill, from its frontmatter.
    ///   - root: The layer root that holds the folder of the skill.
    /// - Returns: The catalog entry of the skill.
    /// - Throws: A ``CatalogGeneratorError`` when the file cannot be read.
    private func catalogSkill(name: String, description: String, inLayerRoot root: URL) throws -> CatalogSkill {
        let url = root
            .appendingPathComponent(name, isDirectory: true)
            .appendingPathComponent(MarketplaceIdentity.skillFileName)
        guard let contents = try? Data(contentsOf: url) else {
            throw CatalogGeneratorError.unreadableSkillFile(url)
        }
        return CatalogSkill(name: name, description: description, fileContents: contents)
    }
}

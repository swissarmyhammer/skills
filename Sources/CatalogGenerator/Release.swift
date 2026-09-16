import Foundation

/// Writes one release of the marketplace (marketplace.md 3.2).
///
/// A release writes the new version into each file that publishes it: the
/// `VERSION` file, the `metadata.version` line of each `SKILL.md`, and the
/// catalogs. Thus the version of a skill, the version of a catalog, and the
/// name of the tag can never differ.
///
/// The tool checks before it writes, and each check that fails stops the run
/// with a ``ReleaseError`` and no file written:
///
/// - The version is a semantic version.
/// - The working tree is clean.
/// - The tests passed.
/// - Every committed catalog is the output of the generator.
///
/// The two facts the tool cannot read itself arrive in a ``ReleasePreflight``,
/// because no product code of this repository starts `git` or a test runner.
/// `scripts/release` reads them from the host, and `scripts/release-commit`
/// makes the release commit and the release tag after this tool writes.
public enum Release: Sendable {
    /// The line break that ends the `VERSION` file.
    private static let lineBreak = "\n"

    /// One `SKILL.md` file, with the text it holds after the rewrite.
    private struct RewrittenSkillFile {
        /// The file to write.
        let url: URL

        /// The path of the file, relative to the repository root.
        let path: String

        /// The text to write.
        let text: String
    }

    /// Writes one release into a repository.
    ///
    /// - Parameters:
    ///   - version: The release version, of the form `X.Y.Z`.
    ///   - repository: The root of the repository to release.
    ///   - preflight: The state of the repository that the tool cannot read
    ///     itself.
    /// - Returns: The report of the release.
    /// - Throws: A ``ReleaseError`` when a check fails, or a
    ///   ``CatalogGeneratorError`` when the repository cannot be read.
    public static func run(
        version: String, repository: URL, preflight: ReleasePreflight
    ) throws -> ReleaseReport {
        let generator = CatalogGenerator(repositoryRoot: repository)
        try check(version: version, preflight: preflight, with: generator, at: repository)
        let skillFiles = try rewrittenSkillFiles(
            version: version, with: generator, at: repository)
        try Data((version + lineBreak).utf8).write(
            to: repository.appendingPathComponent(CatalogGenerator.versionFileName),
            options: .atomic)
        for file in skillFiles {
            try Data(file.text.utf8).write(to: file.url, options: .atomic)
        }
        let catalogs = try generator.write()
        let changedPaths =
            [CatalogGenerator.versionFileName] + skillFiles.map(\.path) + catalogs.map(\.path)
        return ReleaseReport(version: version, changedPaths: changedPaths)
    }

    /// Holds the repository to each condition of a release.
    ///
    /// - Parameters:
    ///   - version: The release version that the run asks for.
    ///   - preflight: The state of the repository that the tool cannot read
    ///     itself.
    ///   - generator: The generator over the repository.
    ///   - repository: The root of the repository.
    /// - Throws: A ``ReleaseError`` when a condition fails.
    private static func check(
        version: String, preflight: ReleasePreflight, with generator: CatalogGenerator,
        at repository: URL
    ) throws {
        guard SemanticVersion.isSemantic(version) else {
            throw ReleaseError.versionIsNotSemantic(version)
        }
        guard preflight.workingTree == .clean else {
            throw ReleaseError.workingTreeIsDirty
        }
        guard preflight.testRun == .passed else {
            throw ReleaseError.testsAreRed
        }
        let stale = try staleCatalogPaths(with: generator, at: repository)
        guard stale.isEmpty else {
            throw ReleaseError.catalogsAreStale(stale)
        }
    }

    /// The path of each committed catalog that is not the output of the
    /// generator now.
    ///
    /// A file that is not there also counts as stale, because a client would
    /// read nothing at that path.
    ///
    /// - Parameters:
    ///   - generator: The generator over the repository.
    ///   - repository: The root of the repository.
    /// - Returns: The paths, in the write order of the generator.
    /// - Throws: A ``CatalogGeneratorError`` when the repository cannot be
    ///   read.
    private static func staleCatalogPaths(
        with generator: CatalogGenerator, at repository: URL
    ) throws -> [String] {
        try generator.generate()
            .filter { file in
                let committed = try? Data(contentsOf: repository.appendingPathComponent(file.path))
                return committed != file.contents
            }
            .map(\.path)
    }

    /// The new text of each `SKILL.md` file of the library.
    ///
    /// The run reads and rewrites every file before it writes one, thus a file
    /// that holds no metadata version line stops the release with each file of
    /// the repository as it was.
    ///
    /// - Parameters:
    ///   - version: The release version to write.
    ///   - generator: The generator over the repository.
    ///   - repository: The root of the repository.
    /// - Returns: One entry for each skill, in name order.
    /// - Throws: A ``ReleaseError`` when a file holds no metadata version line,
    ///   or a ``CatalogGeneratorError`` when a file cannot be read.
    private static func rewrittenSkillFiles(
        version: String, with generator: CatalogGenerator, at repository: URL
    ) throws -> [RewrittenSkillFile] {
        let root = repository.appendingPathComponent(
            MarketplaceIdentity.skillsFolderName, isDirectory: true)
        return try generator.librarySkills().map { skill in
            let url = root
                .appendingPathComponent(skill.id, isDirectory: true)
                .appendingPathComponent(MarketplaceIdentity.skillFileName)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                throw CatalogGeneratorError.unreadableSkillFile(url)
            }
            guard let rewritten = SkillVersionRewrite.rewritten(text: text, version: version)
            else {
                throw ReleaseError.skillFileHoldsNoVersion(url)
            }
            return RewrittenSkillFile(
                url: url, path: MarketplaceIdentity.skillFilePath(name: skill.id),
                text: rewritten)
        }
    }
}

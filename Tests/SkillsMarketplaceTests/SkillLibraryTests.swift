import Foundation
import FoundationModelsSkills
import Testing

/// Holds the checked-in skill library to the rules the client applies when it
/// loads this marketplace (marketplace.md 3.6).
///
/// The suite builds a `SkillsRegistry` over the one layer root of this
/// repository, `skills/`, with the same untrusted render policy a marketplace
/// layer gets in a host. Thus a skill that the host would refuse, or load with
/// changed visibility, fails the build here instead of in a user's session.
@Suite("Skill library")
struct SkillLibraryTests {
    /// The diagnostic severities that block a release of this marketplace.
    ///
    /// `.skip` means the skill did not load at all, and `.warning` means it
    /// loaded with a rule violation. Both are faults of this repository, thus
    /// both fail the suite. `.advisory` is not blocking: it reports a
    /// condition, such as an unknown frontmatter key, that the host loads and
    /// uses as written.
    private static let blockingSeverities: Set<SkillDiagnostic.Severity> = [.skip, .warning]

    /// The repository root, derived from this source file's own path: three
    /// levels up from `Tests/SkillsMarketplaceTests/<file>.swift`.
    ///
    /// The `thisFile` default (`#filePath`) expands at the call site, and
    /// every file of this test target is in `Tests/SkillsMarketplaceTests/`,
    /// thus the three-levels-up derivation is the same for each caller.
    /// Resolution from the source path keeps the suite hermetic: it can never
    /// reach a real home directory or an installed copy of the marketplace.
    ///
    /// - Parameter thisFile: The calling source file's path. Defaults to the
    ///   call site's `#filePath`.
    /// - Returns: The repository root URL.
    private static func repositoryRoot(thisFile: String = #filePath) -> URL {
        URL(fileURLWithPath: thisFile)
            .deletingLastPathComponent()  // <file>.swift -> SkillsMarketplaceTests/
            .deletingLastPathComponent()  // SkillsMarketplaceTests/ -> Tests/
            .deletingLastPathComponent()  // Tests/ -> repository root
    }

    /// The one layer root of this marketplace: `skills/`, which holds every
    /// skill as a direct child, plus the `_partials/` folder (marketplace.md
    /// 3.2).
    ///
    /// - Parameter thisFile: Forwarded to ``repositoryRoot(thisFile:)``.
    /// - Returns: The `skills/` directory URL.
    private static func skillsRoot(thisFile: String = #filePath) -> URL {
        repositoryRoot(thisFile: thisFile)
            .appendingPathComponent("skills", isDirectory: true)
    }

    /// Every skill in `skills/` loads with no blocking diagnostic.
    ///
    /// An empty library passes: a marketplace with no skill yet has nothing to
    /// report. The test also holds the layer root itself, because a registry
    /// over a directory that is not there reports nothing at all and would
    /// otherwise pass.
    @Test("The skill library raises no blocking diagnostic")
    func libraryHasNoBlockingDiagnostics() throws {
        let root = Self.skillsRoot()
        try #require(
            FileManager.default.fileExists(atPath: root.path),
            "The layer root \(root.path) is not there, thus the suite would read an empty library.")

        let registry = SkillsRegistry(roots: [root])
        let blocking = registry.diagnostics.filter { Self.blockingSeverities.contains($0.severity) }
        let report = blocking.map(\.description).joined(separator: "\n")
        #expect(
            blocking.isEmpty,
            "The skill library raised \(blocking.count) blocking diagnostic(s):\n\(report)")
    }
}

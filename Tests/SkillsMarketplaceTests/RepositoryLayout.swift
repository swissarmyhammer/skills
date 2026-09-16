import Foundation

/// The folders of this repository, derived from the path of a source file of
/// this test target.
///
/// Resolution from the source path keeps every suite hermetic: a suite can
/// never reach a real home directory or an installed copy of the marketplace.
internal enum RepositoryLayout {
    /// The name of the one layer root of this marketplace (marketplace.md 3.2).
    private static let skillsFolderName = "skills"

    /// The repository root, derived from the caller's own path: three levels up
    /// from `Tests/SkillsMarketplaceTests/<file>.swift`.
    ///
    /// The `thisFile` default (`#filePath`) expands at the call site, and every
    /// file of this test target is in `Tests/SkillsMarketplaceTests/`, thus the
    /// three-levels-up derivation is the same for each caller.
    ///
    /// - Parameter thisFile: The calling source file's path. Defaults to the
    ///   call site's `#filePath`.
    /// - Returns: The repository root URL.
    internal static func repositoryRoot(thisFile: String = #filePath) -> URL {
        URL(fileURLWithPath: thisFile)
            .deletingLastPathComponent()  // <file>.swift -> SkillsMarketplaceTests/
            .deletingLastPathComponent()  // SkillsMarketplaceTests/ -> Tests/
            .deletingLastPathComponent()  // Tests/ -> repository root
    }

    /// The one layer root of this marketplace: `skills/`, which holds every
    /// skill as a direct child, plus the `_partials/` folder.
    ///
    /// - Parameter thisFile: Forwarded to ``repositoryRoot(thisFile:)``.
    /// - Returns: The `skills/` directory URL.
    internal static func skillsRoot(thisFile: String = #filePath) -> URL {
        repositoryRoot(thisFile: thisFile)
            .appendingPathComponent(skillsFolderName, isDirectory: true)
    }
}

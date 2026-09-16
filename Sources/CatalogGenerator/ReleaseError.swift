import Foundation

/// What stops ``Release`` from making a release.
///
/// Each case is a refusal: the tool writes nothing, and a person reads which
/// state to correct. A release tool that can tag a tree nobody checked gives a
/// user a version that names bytes that fail, thus a refusal is the safe end of
/// a run.
internal enum ReleaseError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The version is not a semantic version of the form `X.Y.Z`.
    case versionIsNotSemantic(String)

    /// The working tree holds a change that is not committed.
    case workingTreeIsDirty

    /// A test of the repository failed.
    case testsAreRed

    /// A committed catalog is not the output of the generator. The value names
    /// each file that is not current.
    case catalogsAreStale([String])

    /// A `SKILL.md` file holds no `metadata.version` line to rewrite.
    case skillFileHoldsNoVersion(URL)

    /// The text of the refusal, which names the state to correct.
    internal var description: String {
        switch self {
        case .versionIsNotSemantic(let version):
            "The version \(version) is not a semantic version of the form X.Y.Z."
        case .workingTreeIsDirty:
            "The working tree holds a change that is not committed. Commit it, or put it away."
        case .testsAreRed:
            "A test of the repository failed. A release names bytes that pass."
        case .catalogsAreStale(let paths):
            "These catalogs are not the output of the generator: \(paths.joined(separator: ", ")). "
                + "Run scripts/generate-catalogs and commit the result."
        case .skillFileHoldsNoVersion(let url):
            "The skill file \(url.path) holds no metadata version line."
        }
    }
}

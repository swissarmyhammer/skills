/// What one release wrote (marketplace.md 3.2).
///
/// The `release` executable prints the paths, thus a person reads which files
/// to look at before the release commit.
public struct ReleaseReport: Sendable, Equatable {
    /// The release version that the run wrote.
    public let version: String

    /// The path of each file that the run wrote, relative to the repository
    /// root, in write order.
    public let changedPaths: [String]

    /// Makes the report of one release.
    ///
    /// - Parameters:
    ///   - version: The release version that the run wrote.
    ///   - changedPaths: The path of each file that the run wrote.
    public init(version: String, changedPaths: [String]) {
        self.version = version
        self.changedPaths = changedPaths
    }
}

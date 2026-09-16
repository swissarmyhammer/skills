/// The release tag of the marketplace: the letter `v` and the release version
/// (marketplace.md 3.6 step 4).
///
/// CI runs for a `v*` tag, and the test target reads the tag of the run from
/// here. Thus a tag that does not name the version of the repository fails the
/// CI run of the tag, and the release never reaches a user under a name that
/// says one version while the files say another.
internal enum ReleaseTag {
    /// The letter that opens the name of a release tag.
    private static let tagPrefix = "v"

    /// The name of the environment value that names the kind of the reference
    /// of a CI run.
    private static let referenceKindName = "GITHUB_REF_TYPE"

    /// The name of the environment value that names the reference of a CI run.
    private static let referenceName = "GITHUB_REF_NAME"

    /// The value of ``referenceKindName`` for a run that is for a tag.
    private static let tagReferenceKind = "tag"

    /// The release version that the reference of a CI run names.
    ///
    /// - Parameter environment: The environment of the run.
    /// - Returns: The version, or `nil` when the run is not for a release tag.
    internal static func version(inEnvironment environment: [String: String]) -> String? {
        guard environment[referenceKindName] == tagReferenceKind,
            let name = environment[referenceName],
            name.hasPrefix(tagPrefix)
        else {
            return nil
        }
        return String(name.dropFirst(tagPrefix.count))
    }
}

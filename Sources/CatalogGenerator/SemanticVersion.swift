/// The form of a release version of this marketplace: `MAJOR.MINOR.PATCH`,
/// where each part is a number with no leading zero.
///
/// The marketplace publishes no pre-release version, thus the form takes no
/// `-alpha` part and no `+build` part. A version of any other form stops a
/// release, because the version becomes the name of a tag that nobody can
/// change after a push.
internal enum SemanticVersion {
    /// The number of parts of a version.
    private static let partCount = 3

    /// The mark between two parts of a version.
    private static let partSeparator: Character = "."

    /// The digit that may not open a part of more than one digit.
    private static let zeroDigit: Character = "0"

    /// Whether one text is a semantic version of this marketplace.
    ///
    /// - Parameter text: The text to read.
    /// - Returns: `true` when the text is of the form `MAJOR.MINOR.PATCH`.
    internal static func isSemantic(_ text: String) -> Bool {
        let parts = text.split(separator: partSeparator, omittingEmptySubsequences: false)
        return parts.count == partCount && parts.allSatisfy(isNumericIdentifier)
    }

    /// Whether one part of a version is a number with no leading zero.
    ///
    /// - Parameter part: The part to read.
    /// - Returns: `true` when the part is such a number.
    private static func isNumericIdentifier(_ part: Substring) -> Bool {
        !part.isEmpty
            && part.allSatisfy { $0.isASCII && $0.isNumber }
            && (part.count == 1 || part.first != zeroDigit)
    }
}

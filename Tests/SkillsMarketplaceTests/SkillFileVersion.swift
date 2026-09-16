import Foundation

/// Reads the `metadata.version` line of a `SKILL.md` file, with a scan written
/// in the test target and not taken from the release tool.
///
/// The release tool writes that line. A test that read the line back with the
/// code of the tool could pass on a line no reader understands, thus this
/// target reads the file with a scan of its own.
internal enum SkillFileVersion {
    /// The key that opens the metadata block of the frontmatter.
    private static let metadataKey = "metadata:"

    /// The key of the version line inside the metadata block.
    private static let versionKey = "version:"

    /// The mark that a YAML value uses around a string.
    private static let quotationMark: Character = "\""

    /// The `metadata.version` value of one `SKILL.md` text.
    ///
    /// A line of the metadata block has leading space. Thus the scan opens at
    /// the `metadata:` line and stops at the first line with no leading space,
    /// which is the end of the block.
    ///
    /// - Parameter text: The text of the file.
    /// - Returns: The version, or `nil` when the file holds no metadata version
    ///   line.
    internal static func version(inText text: String) -> String? {
        var isInMetadata = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let hasLeadingSpace = line.first == " "
            if String(line) == metadataKey {
                isInMetadata = true
            } else if isInMetadata && !hasLeadingSpace {
                return nil
            } else if isInMetadata && hasLeadingSpace {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix(versionKey) {
                    let value = trimmed.dropFirst(versionKey.count)
                        .trimmingCharacters(in: .whitespaces)
                    return String(value.filter { $0 != quotationMark })
                }
            }
        }
        return nil
    }

    /// The `metadata.version` value of one `SKILL.md` file.
    ///
    /// - Parameter url: The file to read.
    /// - Returns: The version, or `nil` when the file holds no metadata version
    ///   line.
    /// - Throws: An error when the file cannot be read.
    internal static func version(ofSkillAt url: URL) throws -> String? {
        version(inText: try String(contentsOf: url, encoding: .utf8))
    }
}

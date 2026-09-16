import Foundation

/// Writes a new value into the `metadata.version` line of a `SKILL.md` file,
/// and keeps every other byte of the file (marketplace.md 3.2).
///
/// A skill file is a document that a person wrote. The release tool changes one
/// line of it, thus the rewrite works on lines and never on a parsed model: a
/// model would write the file back in the form of the encoder, and would lose
/// the comments, the order of the keys, and the form of each value.
internal enum SkillVersionRewrite {
    /// The key that opens the metadata block of the frontmatter.
    private static let metadataKey = "metadata:"

    /// The key of the version line inside the metadata block.
    private static let versionKey = "version:"

    /// The mark that a YAML value uses around a string.
    private static let quotationMark = "\""

    /// The mark between two lines of the file.
    private static let lineBreak: Character = "\n"

    /// The space that opens each line of the metadata block.
    private static let indentSpace: Character = " "

    /// The text of one `SKILL.md` file with a new `metadata.version` value.
    ///
    /// - Parameters:
    ///   - text: The text of the file.
    ///   - version: The version to write.
    /// - Returns: The new text, or `nil` when the file holds no metadata
    ///   version line.
    internal static func rewritten(text: String, version: String) -> String? {
        let lines = text.split(separator: lineBreak, omittingEmptySubsequences: false)
        guard let index = versionLineIndex(inLines: lines) else {
            return nil
        }
        let indent = lines[index].prefix { $0 == indentSpace }
        let versionLine = "\(indent)\(versionKey) \(quotationMark)\(version)\(quotationMark)"
        return
            lines
            .enumerated()
            .map { $0.offset == index ? versionLine : String($0.element) }
            .joined(separator: String(lineBreak))
    }

    /// The place of the `metadata.version` line in the lines of one file.
    ///
    /// A line of the metadata block opens with space. Thus the block runs from
    /// the line after `metadata:` to the first line that opens with no space.
    ///
    /// - Parameter lines: The lines of the file.
    /// - Returns: The place of the line, or `nil` when there is no such line.
    private static func versionLineIndex(inLines lines: [Substring]) -> Int? {
        guard let metadataIndex = lines.firstIndex(where: { String($0) == metadataKey }) else {
            return nil
        }
        let blockStart = lines.index(after: metadataIndex)
        let blockEnd =
            lines[blockStart...].firstIndex { $0.first != indentSpace } ?? lines.endIndex
        return lines[blockStart..<blockEnd].firstIndex {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix(versionKey)
        }
    }
}

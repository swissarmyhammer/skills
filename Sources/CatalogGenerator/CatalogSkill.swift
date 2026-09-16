import CryptoKit
import Foundation

/// One skill of the library, as the catalogs report it.
///
/// The generator builds the value from the skill folder itself: the name is the
/// folder name, the description is the frontmatter description the client
/// loads, and the digest is taken over the bytes of the `SKILL.md` file.
internal struct CatalogSkill: Sendable, Hashable {
    /// The opening text of a digest, which names the hash function that the
    /// agentskills discovery index asks for.
    private static let digestPrefix = "sha256:"

    /// The format of one byte of a digest: two lower-case hexadecimal digits.
    private static let digestByteFormat = "%02x"

    /// The name of the skill, which is the name of its folder.
    internal let name: String

    /// The description of the skill, from its frontmatter.
    internal let description: String

    /// The digest of the `SKILL.md` file, in the form `sha256:<hexadecimal>`.
    internal let digest: String

    /// Makes the catalog entry of one skill.
    ///
    /// - Parameters:
    ///   - name: The name of the skill, which is the name of its folder.
    ///   - description: The description of the skill, from its frontmatter.
    ///   - fileContents: The bytes of the `SKILL.md` file of the skill.
    internal init(name: String, description: String, fileContents: Data) {
        self.name = name
        self.description = description
        let hexadecimal = SHA256.hash(data: fileContents)
            .map { String(format: Self.digestByteFormat, $0) }
            .joined()
        digest = Self.digestPrefix + hexadecimal
    }
}

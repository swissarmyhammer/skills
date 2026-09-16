/// The agentskills discovery index, `.well-known/agent-skills/index.json`
/// (marketplace.md 3.2).
///
/// A client that reads the well-known URL takes the list of skills and the
/// digest of each one. The digest is the change key: a client that holds a
/// skill compares the digest it has with the digest here, and it fetches the
/// file again only when the two differ.
public struct DiscoveryIndex: Sendable, Hashable, Codable {
    /// One skill of the index.
    public struct Entry: Sendable, Hashable, Codable {
        /// The name of the skill.
        public let name: String

        /// The form of the artifact: one `SKILL.md` file.
        public let type: String

        /// The description of the skill, from its frontmatter.
        public let description: String

        /// The URL of the `SKILL.md` file, relative to the root of the site.
        public let url: String

        /// The digest of the bytes of the `SKILL.md` file.
        public let digest: String
    }

    /// The path of the index in the repository.
    public static let path = ".well-known/agent-skills/index.json"

    /// The schema of the format: version 0.2.0 of the discovery index.
    private static let schema = "https://schemas.agentskills.io/discovery/0.2.0/schema.json"

    /// The form of an artifact that is one `SKILL.md` file.
    private static let skillFileType = "skill-md"

    /// The schema of the format.
    public let schemaURL: String

    /// The skills of the marketplace, in name order.
    public let skills: [Entry]

    /// The keys of an index.
    private enum CodingKeys: String, CodingKey {
        case schemaURL = "$schema"
        case skills
    }

    /// Makes the discovery index of this marketplace.
    ///
    /// - Parameter skills: The skills of the library, in name order.
    internal init(skills: [CatalogSkill]) {
        schemaURL = Self.schema
        self.skills = skills.map { skill in
            Entry(
                name: skill.name,
                type: Self.skillFileType,
                description: skill.description,
                url: MarketplaceIdentity.skillFileURL(name: skill.name),
                digest: skill.digest)
        }
    }
}

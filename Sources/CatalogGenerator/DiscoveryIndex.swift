/// The agentskills discovery index, `.well-known/agent-skills/index.json`
/// (marketplace.md 3.2).
///
/// A client that reads the well-known URL takes the list of skills and the
/// digest of each one. The digest is the change key: a client that holds a
/// skill compares the digest it has with the digest here, and it fetches the
/// file again only when the two differ.
///
/// The generator only writes an index, thus the type is `Encodable` only. A
/// test that reads the committed file decodes it with a model of its own, which
/// is a truth outside the generator.
internal struct DiscoveryIndex: Sendable, Hashable, Encodable {
    /// One skill of the index.
    internal struct Entry: Sendable, Hashable, Encodable {
        /// The name of the skill.
        internal let name: String

        /// The form of the artifact: one `SKILL.md` file.
        internal let type: String

        /// The description of the skill, from its frontmatter.
        internal let description: String

        /// The URL of the `SKILL.md` file, relative to the root of the site.
        internal let url: String

        /// The digest of the bytes of the `SKILL.md` file.
        internal let digest: String
    }

    /// The path of the index in the repository.
    internal static let path = ".well-known/agent-skills/index.json"

    /// The schema of the format: version 0.2.0 of the discovery index.
    private static let schema = "https://schemas.agentskills.io/discovery/0.2.0/schema.json"

    /// The form of an artifact that is one `SKILL.md` file.
    private static let skillFileType = "skill-md"

    /// The schema of the format.
    internal let schemaURL: String

    /// The skills of the marketplace, in name order.
    internal let skills: [Entry]

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

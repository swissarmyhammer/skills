/// The primary catalog of the marketplace, `.claude-plugin/marketplace.json`
/// (marketplace.md 3.3).
///
/// The client reads `name`, `owner`, `metadata.version`, and `plugins`, and it
/// ignores every other key (marketplace.md 5.2). Claude, Codex, and Copilot
/// each read this file, thus it is the primary catalog.
///
/// The catalog holds one plugin that lists every skill, with the source `./`
/// and `strict` false. Thus the repository needs no `plugin.json` file.
///
/// The generator only writes a catalog, thus the type is `Encodable` only. A
/// test that reads a committed file decodes it with a model of its own, which
/// is a truth outside the generator.
internal struct ClaudeCatalog: Sendable, Hashable, Encodable {
    /// The owner of a marketplace.
    internal struct Owner: Sendable, Hashable, Encodable {
        /// The name of the owner.
        internal let name: String
    }

    /// The release metadata of a catalog.
    internal struct Metadata: Sendable, Hashable, Encodable {
        /// What the marketplace gives, for a person who reads a listing.
        internal let description: String

        /// The release version of the catalog, which is the `VERSION` file of
        /// the repository.
        internal let version: String
    }

    /// One plugin of a catalog: a named list of skills.
    internal struct Plugin: Sendable, Hashable, Encodable {
        /// The name of the plugin.
        internal let name: String

        /// The folder of the files of the plugin, relative to the repository
        /// root.
        internal let source: String

        /// Whether the plugin needs a `plugin.json` file. This plugin does not,
        /// because it lists its skills itself.
        internal let strict: Bool

        /// What the plugin gives.
        internal let description: String

        /// The skill folders of the plugin, relative to ``source``, in name
        /// order.
        internal let skills: [String]
    }

    /// The path of the catalog in the repository.
    internal static let path = ".claude-plugin/marketplace.json"

    /// The schema of the format, which an editor reads to check the file.
    private static let schema = "https://anthropic.com/claude-code/marketplace.schema.json"

    /// Whether the one plugin needs a `plugin.json` file.
    private static let pluginIsStrict = false

    /// The schema of the format.
    internal let schemaURL: String

    /// The name of the marketplace.
    internal let name: String

    /// The owner of the marketplace.
    internal let owner: Owner

    /// The release metadata of the catalog.
    internal let metadata: Metadata

    /// The plugins of the catalog: one plugin that lists every skill.
    internal let plugins: [Plugin]

    /// The keys of a catalog.
    private enum CodingKeys: String, CodingKey {
        case schemaURL = "$schema"
        case name
        case owner
        case metadata
        case plugins
    }

    /// Makes the catalog of this marketplace.
    ///
    /// - Parameters:
    ///   - version: The release version, from the `VERSION` file.
    ///   - skills: The skills of the library, in name order.
    internal init(version: String, skills: [CatalogSkill]) {
        schemaURL = Self.schema
        name = MarketplaceIdentity.name
        owner = Owner(name: MarketplaceIdentity.owner)
        metadata = Metadata(description: MarketplaceIdentity.summary, version: version)
        plugins = [
            Plugin(
                name: MarketplaceIdentity.pluginName,
                source: MarketplaceIdentity.pluginSource,
                strict: Self.pluginIsStrict,
                description: MarketplaceIdentity.pluginSummary,
                skills: skills.map { MarketplaceIdentity.pluginSkillPath(name: $0.name) }),
        ]
    }
}

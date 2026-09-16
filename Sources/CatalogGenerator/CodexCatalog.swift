/// The Codex catalog of the marketplace, `.agents/plugins/marketplace.json`.
///
/// Codex reads this file, and the client reads it when the Claude catalog is
/// not there (marketplace.md 5.2). The one plugin has a `local` source at `./`
/// and no `skills` array, thus a reader takes the folders of `skills/` that
/// hold a `SKILL.md` file. That is the same set of skills the Claude catalog
/// lists, and `_partials/` is not in it, because that folder holds no
/// `SKILL.md` file.
internal struct CodexCatalog: Sendable, Hashable, Encodable {
    /// How a reader shows the marketplace to a person.
    internal struct Interface: Sendable, Hashable, Encodable {
        /// The name of the marketplace for a person who reads a listing.
        internal let displayName: String
    }

    /// The location of the files of a plugin.
    internal struct Source: Sendable, Hashable, Encodable {
        /// The kind of the source: a folder of this repository.
        internal let kind: String

        /// The folder, relative to the repository root.
        internal let path: String

        /// The keys of a source. The kind is the `source` key, which is the
        /// spelling the client reads.
        private enum CodingKeys: String, CodingKey {
            case kind = "source"
            case path
        }
    }

    /// One plugin of the catalog.
    internal struct Plugin: Sendable, Hashable, Encodable {
        /// The name of the plugin.
        internal let name: String

        /// The location of the files of the plugin.
        internal let source: Source
    }

    /// The path of the catalog in the repository.
    internal static let path = ".agents/plugins/marketplace.json"

    /// The kind of a source that names a folder of this repository.
    private static let localSourceKind = "local"

    /// The name of the marketplace.
    internal let name: String

    /// How a reader shows the marketplace to a person.
    internal let interface: Interface

    /// The plugins of the catalog: the one plugin of the repository.
    internal let plugins: [Plugin]

    /// Makes the Codex catalog of this marketplace.
    internal init() {
        name = MarketplaceIdentity.name
        interface = Interface(displayName: MarketplaceIdentity.displayName)
        plugins = [
            Plugin(
                name: MarketplaceIdentity.pluginName,
                source: Source(kind: Self.localSourceKind, path: MarketplaceIdentity.pluginSource)),
        ]
    }
}

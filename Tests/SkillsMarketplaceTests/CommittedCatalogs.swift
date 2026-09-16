// The committed catalog files, as a reader outside the generator decodes them.
//
// The generator only writes a catalog, thus each of its own types encodes only.
// These models read a committed file back, with the key names of the published
// format written here a second time. Thus a test holds each value equal to a
// literal of its own: a changed value in the generator fails a test, and does
// not pass after one run of the generator.
//
// The path of a file is the most published value of a catalog, because a client
// finds the file by that name. Thus each model writes its own path here as a
// literal too, and no test takes a path from the generator.

/// The Claude catalog, `.claude-plugin/marketplace.json`.
internal struct CommittedClaudeCatalog: Decodable {
    /// The path a client reads the Claude catalog from.
    internal static let path = ".claude-plugin/marketplace.json"

    /// The owner of the marketplace.
    internal struct Owner: Decodable {
        /// The name of the owner.
        internal let name: String
    }

    /// The release metadata of the catalog.
    internal struct Metadata: Decodable {
        /// The release version of the catalog.
        internal let version: String
    }

    /// One plugin of the catalog.
    internal struct Plugin: Decodable {
        /// The name of the plugin.
        internal let name: String

        /// The folder of the files of the plugin.
        internal let source: String

        /// Whether the plugin needs a `plugin.json` file.
        internal let strict: Bool

        /// The skill folders of the plugin, relative to ``source``.
        internal let skills: [String]
    }

    /// The name of the marketplace.
    internal let name: String

    /// The owner of the marketplace.
    internal let owner: Owner

    /// The release metadata of the catalog.
    internal let metadata: Metadata

    /// The plugins of the catalog.
    internal let plugins: [Plugin]
}

/// The Codex catalog, `.agents/plugins/marketplace.json`.
internal struct CommittedCodexCatalog: Decodable {
    /// The path a client reads the Codex catalog from.
    internal static let path = ".agents/plugins/marketplace.json"

    /// How a reader shows the marketplace to a person.
    internal struct Interface: Decodable {
        /// The name of the marketplace for a person who reads a listing.
        internal let displayName: String
    }

    /// The location of the files of a plugin.
    internal struct Source: Decodable {
        /// The kind of the source, which the file writes as the `source` key.
        internal let kind: String

        /// The folder, relative to the repository root.
        internal let path: String

        /// The keys of a source.
        private enum CodingKeys: String, CodingKey {
            case kind = "source"
            case path
        }
    }

    /// One plugin of the catalog.
    internal struct Plugin: Decodable {
        /// The name of the plugin.
        internal let name: String

        /// The location of the files of the plugin.
        internal let source: Source
    }

    /// The name of the marketplace.
    internal let name: String

    /// How a reader shows the marketplace to a person.
    internal let interface: Interface

    /// The plugins of the catalog.
    internal let plugins: [Plugin]
}

/// The Codex plugin manifest, `.codex-plugin/plugin.json`.
internal struct CommittedCodexPluginManifest: Decodable {
    /// The path a client reads the Codex plugin manifest from.
    internal static let path = ".codex-plugin/plugin.json"

    /// The name of the plugin.
    internal let name: String

    /// The release version of the plugin.
    internal let version: String

    /// The folder that holds the skills of the plugin.
    internal let skills: String
}

/// The agentskills discovery index, `.well-known/agent-skills/index.json`.
internal struct CommittedDiscoveryIndex: Decodable {
    /// The path a client reads the discovery index from.
    internal static let path = ".well-known/agent-skills/index.json"

    /// One skill of the index.
    internal struct Entry: Decodable {
        /// The name of the skill.
        internal let name: String

        /// The form of the artifact.
        internal let type: String

        /// The URL of the `SKILL.md` file of the skill.
        internal let url: String

        /// The digest of the bytes of the `SKILL.md` file.
        internal let digest: String
    }

    /// The skills of the marketplace.
    internal let skills: [Entry]
}

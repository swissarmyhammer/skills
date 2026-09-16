/// The Codex plugin manifest of the repository, `.codex-plugin/plugin.json`.
///
/// Codex reads the manifest beside the Codex catalog: the catalog names the
/// plugin, and the manifest names the version of the plugin and the folder
/// that holds its skills.
///
/// The manifest claims no `$schema`. The `agent-plugins.org` 1.0.0 schema
/// holds no property for a skills folder, thus a claim of that schema would not
/// agree with the `skills` key this manifest needs.
internal struct CodexPluginManifest: Sendable, Hashable, Encodable {
    /// The path of the manifest in the repository.
    internal static let path = ".codex-plugin/plugin.json"

    /// The name of the plugin, which is the name the Codex catalog gives it.
    internal let name: String

    /// The release version of the plugin, which is the `VERSION` file of the
    /// repository.
    internal let version: String

    /// The folder that holds the skills of the plugin, relative to the
    /// repository root.
    internal let skills: String

    /// Makes the plugin manifest of this repository.
    ///
    /// - Parameter version: The release version, from the `VERSION` file.
    internal init(version: String) {
        name = MarketplaceIdentity.pluginName
        self.version = version
        skills = MarketplaceIdentity.skillsFolderPath
    }
}

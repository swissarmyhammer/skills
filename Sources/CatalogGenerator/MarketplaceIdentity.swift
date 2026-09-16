/// The fixed identity of this marketplace, which every generated catalog
/// repeats (marketplace.md 3.1 and 3.3).
///
/// One enum holds each name, thus the Claude catalog, the Codex catalog, and
/// the Codex plugin manifest can never name the marketplace in two ways.
internal enum MarketplaceIdentity {
    /// The name of the marketplace. After a fetch, the client uses it as the
    /// display id of the marketplace (marketplace.md 5.3).
    internal static let name = "swissarmyhammer-skills"

    /// The name of the marketplace for a person who reads a listing.
    internal static let displayName = "SwissArmyHammer Skills"

    /// The owner of the marketplace.
    internal static let owner = "swissarmyhammer"

    /// What the marketplace gives, for a person who reads a listing.
    internal static let summary = "Engineering workflow skills from swissarmyhammer."

    /// The name of the one plugin that lists every skill.
    internal static let pluginName = "swissarmyhammer"

    /// What the one plugin gives.
    internal static let pluginSummary = "All swissarmyhammer skills."

    /// The folder of the files of the plugin: the repository root itself.
    internal static let pluginSource = "./"

    /// The name of the one layer root of the repository (marketplace.md 3.2).
    internal static let skillsFolderName = "skills"

    /// The layer root, as a catalog writes it: relative to the plugin source.
    internal static let skillsFolderPath = "./\(skillsFolderName)"

    /// The name of the file of a skill. A folder of the layer root is a skill
    /// when it holds this file.
    internal static let skillFileName = "SKILL.md"

    /// The folder of one skill, as the Claude catalog writes it.
    ///
    /// - Parameter name: The name of the skill, which is its folder name.
    /// - Returns: The path, relative to the plugin source.
    internal static func pluginSkillPath(name: String) -> String {
        "\(skillsFolderPath)/\(name)"
    }

    /// The `SKILL.md` of one skill, as a path of the repository.
    ///
    /// ``Release`` reports the file it wrote by this path.
    ///
    /// - Parameter name: The name of the skill, which is its folder name.
    /// - Returns: The path, relative to the repository root.
    internal static func skillFilePath(name: String) -> String {
        "\(skillsFolderName)/\(name)/\(skillFileName)"
    }

    /// The `SKILL.md` of one skill, as the discovery index writes it.
    ///
    /// - Parameter name: The name of the skill, which is its folder name.
    /// - Returns: The URL, relative to the root of the site that publishes the
    ///   repository.
    internal static func skillFileURL(name: String) -> String {
        "/\(skillsFolderName)/\(name)/\(skillFileName)"
    }
}

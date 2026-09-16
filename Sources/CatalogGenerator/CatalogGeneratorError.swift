import Foundation

/// What stops ``CatalogGenerator`` from reading the repository.
///
/// Each case names the file or the folder that the generator could not use,
/// thus a person who runs `scripts/generate-catalogs` reads which path to
/// correct.
///
/// The executable catches the error and reports its text, thus it names no case
/// and the type stays in the module.
internal enum CatalogGeneratorError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The `VERSION` file is not there, or it cannot be read.
    case unreadableVersion(URL)

    /// The `VERSION` file holds no version.
    case emptyVersion(URL)

    /// The layer root holds no skill, thus the catalogs would name none.
    case emptyLibrary(URL)

    /// The `SKILL.md` file of one skill is not there, or it cannot be read.
    case unreadableSkillFile(URL)

    /// The text of the error, which names the path that stopped the run.
    internal var description: String {
        switch self {
        case .unreadableVersion(let url):
            "The generator cannot read the version file \(url.path)."
        case .emptyVersion(let url):
            "The version file \(url.path) holds no version."
        case .emptyLibrary(let url):
            "The layer root \(url.path) holds no skill."
        case .unreadableSkillFile(let url):
            "The generator cannot read the skill file \(url.path)."
        }
    }
}

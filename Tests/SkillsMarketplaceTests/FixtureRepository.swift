import Foundation

/// A small marketplace repository in a temporary folder, for the suites that
/// must write files without a change to the checked-in files of this
/// repository.
///
/// One builder serves every suite, thus the shape of a fixture repository is
/// written one time: a `VERSION` file at the root, and a `skills/` layer root
/// that holds one folder for each skill.
internal enum FixtureRepository {
    /// The name of the one layer root of a marketplace repository.
    internal static let skillsFolderName = "skills"

    /// The name of the file of a skill. A folder of the layer root is a skill
    /// when it holds this file.
    internal static let skillFileName = "SKILL.md"

    /// The name of the file that holds the release version.
    ///
    /// The builder writes the file before any generator runs over the fixture,
    /// thus the name is here and not taken from the generator.
    internal static let versionFileName = "VERSION"

    /// The release version that a new fixture repository holds.
    ///
    /// It is far from the version of this repository, thus a test that reads it
    /// back cannot pass on a checked-in value.
    internal static let version = "9.9.9"

    /// The names of the skills of the fixture library, in the order the builder
    /// writes them, which is not name order.
    internal static let skillNames = ["beta", "alpha"]

    /// The `SKILL.md` text of one skill of the fixture library.
    ///
    /// The frontmatter carries the keys the loader of the client asks for, plus
    /// the `metadata.version` line that the release tool rewrites.
    ///
    /// - Parameters:
    ///   - name: The name of the skill.
    ///   - version: The value of the `metadata.version` line.
    /// - Returns: The text of the file.
    internal static func skillFile(name: String, version: String = version) -> String {
        """
        ---
        name: \(name)
        description: The \(name) skill of the fixture library.
        metadata:
          author: fixture
          version: "\(version)"
        ---

        # \(name)
        """
    }

    /// Builds a repository that holds a `VERSION` file and the fixture library.
    ///
    /// The repository holds no catalog. A caller that needs the catalogs runs
    /// the generator over the root.
    ///
    /// - Returns: The root of the new repository.
    /// - Throws: An error when a folder or a file cannot be written.
    internal static func make() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let skillsRoot = root.appendingPathComponent(skillsFolderName, isDirectory: true)
        for name in skillNames {
            let folder = skillsRoot.appendingPathComponent(name, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try Data(skillFile(name: name).utf8)
                .write(to: folder.appendingPathComponent(skillFileName))
        }
        try Data(version.utf8).write(to: root.appendingPathComponent(versionFileName))
        return root
    }

    /// Reads the files of one repository back from disk.
    ///
    /// - Parameters:
    ///   - paths: The paths of the files, relative to the repository root.
    ///   - root: The root of the repository.
    /// - Returns: The bytes of each file, by path.
    /// - Throws: An error when a file cannot be read.
    internal static func filesOnDisk(
        atPaths paths: [String], inRepositoryAt root: URL
    ) throws -> [String: Data] {
        let files = try paths.map { ($0, try Data(contentsOf: root.appendingPathComponent($0))) }
        return Dictionary(uniqueKeysWithValues: files)
    }

    /// Reads every file of one repository back from disk.
    ///
    /// A refusal test compares the whole repository before and after a run,
    /// thus it holds each file byte for byte and also finds a file that the run
    /// added or removed.
    ///
    /// - Parameter root: The root of the repository.
    /// - Returns: The bytes of each file, by path relative to the root.
    /// - Throws: An error when the folder cannot be read.
    internal static func everyFile(inRepositoryAt root: URL) throws -> [String: Data] {
        let paths = try FileManager.default.subpathsOfDirectory(atPath: root.path)
            .filter { isFile(atPath: root.appendingPathComponent($0).path) }
        return try filesOnDisk(atPaths: paths, inRepositoryAt: root)
    }

    /// Whether one path names a file and not a folder.
    ///
    /// - Parameter path: The path to read.
    /// - Returns: `true` when the path names a file.
    private static func isFile(atPath path: String) -> Bool {
        var isFolder: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isFolder)
        return exists && !isFolder.boolValue
    }
}

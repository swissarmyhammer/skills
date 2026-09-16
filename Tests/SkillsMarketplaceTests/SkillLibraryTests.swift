import Foundation
import FoundationModelsSkills
import Testing

/// Holds the checked-in skill library to the rules the client applies when it
/// loads this marketplace (marketplace.md 3.6).
///
/// The suite builds a `SkillsRegistry` over the one layer root of this
/// repository, `skills/`, with the same untrusted render policy a marketplace
/// layer gets in a host. Thus a skill that the host would refuse, or load with
/// changed visibility, fails the build here instead of in a user's session.
@Suite("Skill library")
struct SkillLibraryTests {
    /// The diagnostic severities that block a release of this marketplace.
    ///
    /// `.skip` means the skill did not load at all, and `.warning` means it
    /// loaded with a rule violation. Both are faults of this repository, thus
    /// both fail the suite. `.advisory` is not blocking: it reports a
    /// condition, such as an unknown frontmatter key, that the host loads and
    /// uses as written.
    private static let blockingSeverities: Set<SkillDiagnostic.Severity> = [.skip, .warning]

    /// Every skill id this marketplace ships, sorted the way
    /// `SkillsRegistry.metadata()` sorts its own rows.
    ///
    /// The list is the checked-in record of the copy of marketplace.md 3.4:
    /// the 24 folders of SwissArmyHammer's `builtin/skills/`. A skill that is
    /// added, dropped, or renamed fails ``copiesAllSkills()`` until a person
    /// updates this list with it.
    private static let expectedSkillIDs = [
        "check-sah",
        "ci",
        "code-context",
        "commit",
        "coverage",
        "deduplicate",
        "detected-projects",
        "double-check",
        "explore",
        "finish",
        "implement",
        "issue",
        "kanban",
        "lsp",
        "make-readme",
        "map",
        "plan",
        "review",
        "sah-help",
        "shell",
        "task",
        "tdd",
        "test",
        "thoughtful",
    ]

    /// The file extension of every text file this marketplace ships.
    ///
    /// The library is Markdown only: a `SKILL.md`, a partial, or a reference
    /// file. ``textFiles(thisFile:)`` keeps these and drops anything else a
    /// tool leaves under the layer root.
    private static let markdownExtension = "md"

    /// The Stencil delimiters a fully rendered body must no longer hold.
    ///
    /// A delimiter that survives the render is text the host never resolved,
    /// thus a user would read it as written instead of as its value.
    private static let templateDelimiters = ["{%", "{{"]

    /// The template text no checked-in file may hold after the conversion of
    /// marketplace.md 3.5.
    ///
    /// `{{version}}` is a SwissArmyHammer build-time value, and `arguments`
    /// is a SwissArmyHammer render variable. This package supplies neither,
    /// thus each one would reach a user as literal text. The two spellings of
    /// the variable cover both the spaced and the unspaced form.
    private static let forbiddenFragments = ["{{version}}", "{{arguments", "{{ arguments"]

    /// The opening text of a Stencil `include` tag.
    private static let includeTagPrefix = "{% include \""

    /// The opening text of a Stencil `include` tag that names a partial of
    /// this marketplace.
    ///
    /// Each partial was copied to `_partials/sah-<name>.md`, thus the prefix
    /// keeps it apart from a partial of the host or of another marketplace
    /// (marketplace.md 3.5).
    private static let marketplaceIncludeTagPrefix = "\(includeTagPrefix)_partials/sah-"

    /// The repository root, derived from this source file's own path: three
    /// levels up from `Tests/SkillsMarketplaceTests/<file>.swift`.
    ///
    /// The `thisFile` default (`#filePath`) expands at the call site, and
    /// every file of this test target is in `Tests/SkillsMarketplaceTests/`,
    /// thus the three-levels-up derivation is the same for each caller.
    /// Resolution from the source path keeps the suite hermetic: it can never
    /// reach a real home directory or an installed copy of the marketplace.
    ///
    /// - Parameter thisFile: The calling source file's path. Defaults to the
    ///   call site's `#filePath`.
    /// - Returns: The repository root URL.
    private static func repositoryRoot(thisFile: String = #filePath) -> URL {
        URL(fileURLWithPath: thisFile)
            .deletingLastPathComponent()  // <file>.swift -> SkillsMarketplaceTests/
            .deletingLastPathComponent()  // SkillsMarketplaceTests/ -> Tests/
            .deletingLastPathComponent()  // Tests/ -> repository root
    }

    /// The one layer root of this marketplace: `skills/`, which holds every
    /// skill as a direct child, plus the `_partials/` folder (marketplace.md
    /// 3.2).
    ///
    /// - Parameter thisFile: Forwarded to ``repositoryRoot(thisFile:)``.
    /// - Returns: The `skills/` directory URL.
    private static func skillsRoot(thisFile: String = #filePath) -> URL {
        repositoryRoot(thisFile: thisFile)
            .appendingPathComponent("skills", isDirectory: true)
    }

    /// Builds the registry every test of this suite reads, over the one layer
    /// root of this repository.
    ///
    /// `SkillsRegistry.init(roots:)` labels each root `.project`, thus every
    /// skill here renders on the untrusted path -- the trust a marketplace
    /// layer also gets in a host. The helper also holds the layer root
    /// itself, because a registry over a directory that is not there reports
    /// nothing at all and would otherwise let each test pass on an empty
    /// library.
    ///
    /// - Parameter thisFile: Forwarded to ``skillsRoot(thisFile:)``.
    /// - Returns: The registry over `skills/`.
    /// - Throws: An error when the layer root is not there.
    private static func makeRegistry(thisFile: String = #filePath) throws -> SkillsRegistry {
        let root = skillsRoot(thisFile: thisFile)
        try #require(
            FileManager.default.fileExists(atPath: root.path),
            "The layer root \(root.path) is not there, thus the suite would read an empty library.")
        return SkillsRegistry(roots: [root])
    }

    /// Every Markdown file under the layer root, at any depth.
    ///
    /// The walk covers a `SKILL.md`, a partial, and a reference file alike,
    /// thus ``noLiquidLeftovers()`` reads the whole shipped library and not
    /// only the files the registry itself loads.
    ///
    /// - Parameter thisFile: Forwarded to ``skillsRoot(thisFile:)``.
    /// - Returns: The file URLs, in directory-walk order.
    /// - Throws: An error when the layer root cannot be walked.
    private static func textFiles(thisFile: String = #filePath) throws -> [URL] {
        let root = skillsRoot(thisFile: thisFile)
        let walk = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil),
            "The layer root \(root.path) cannot be walked, thus the suite would read no file.")
        return walk.compactMap { $0 as? URL }.filter { $0.pathExtension == markdownExtension }
    }

    /// The library holds exactly the skill ids of ``expectedSkillIDs``.
    ///
    /// The comparison keeps order, because `metadata()` sorts by id and the
    /// checked-in list is sorted the same way. Thus a missing skill, a
    /// surplus skill, and a renamed skill each fail here.
    @Test("The skill library holds exactly the checked-in skill ids")
    func copiesAllSkills() throws {
        let registry = try Self.makeRegistry()
        let loadedIDs = registry.metadata().map(\.id)
        #expect(
            loadedIDs == Self.expectedSkillIDs,
            "The skill library holds \(loadedIDs), and the checked-in list holds \(Self.expectedSkillIDs).")
    }

    /// Every skill in `skills/` loads with no blocking diagnostic.
    ///
    /// An empty library passes: a marketplace with no skill yet has nothing to
    /// report. ``makeRegistry(thisFile:)`` holds the layer root itself, thus
    /// a missing root fails instead of reading an empty library.
    @Test("The skill library raises no blocking diagnostic")
    func libraryHasNoBlockingDiagnostics() throws {
        let registry = try Self.makeRegistry()
        let blocking = registry.diagnostics.filter { Self.blockingSeverities.contains($0.severity) }
        let report = blocking.map(\.description).joined(separator: "\n")
        #expect(
            blocking.isEmpty,
            "The skill library raised \(blocking.count) blocking diagnostic(s):\n\(report)")
    }

    /// Every skill renders on the untrusted path, and the rendered body holds
    /// no Stencil delimiter.
    ///
    /// The call renders all three passes with no argument, thus it also
    /// proves that each `{% include %}` resolves to a partial this repository
    /// ships: an include of a name the layer root does not hold raises a
    /// render error rather than returning text.
    @Test("Every skill renders untrusted with no template left in the body")
    func everySkillRendersUntrusted() throws {
        let registry = try Self.makeRegistry()
        for id in Self.expectedSkillIDs {
            let body = try registry.call(id: id, arguments: [])
            for delimiter in Self.templateDelimiters {
                #expect(
                    !body.contains(delimiter),
                    "Skill \(id) renders with the delimiter \(delimiter) still in its body.")
            }
        }
    }

    /// No checked-in file holds template text the conversion of
    /// marketplace.md 3.5 had to remove.
    ///
    /// The scan reads the files on disk rather than the rendered bodies, thus
    /// it also covers a reference file, which the registry never renders.
    @Test("No checked-in file holds an unconverted template")
    func noLiquidLeftovers() throws {
        for file in try Self.textFiles() {
            let text = try String(contentsOf: file, encoding: .utf8)
            for fragment in Self.forbiddenFragments {
                #expect(
                    !text.contains(fragment),
                    "\(file.path) holds the unconverted template text \(fragment).")
            }
            let includeCount = text.ranges(of: Self.includeTagPrefix).count
            let marketplaceIncludeCount = text.ranges(of: Self.marketplaceIncludeTagPrefix).count
            #expect(
                includeCount == marketplaceIncludeCount,
                """
                \(file.path) holds \(includeCount) include tag(s), of which \
                \(marketplaceIncludeCount) name a partial of this marketplace; \
                every include must name a `_partials/sah-` partial.
                """)
        }
    }
}

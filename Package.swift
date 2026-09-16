// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Single source of truth for the test-target name -- avoids repeating the
// literal across the target and its dependency list below.
let testTargetName = "SkillsMarketplaceTests"

// Single source of truth for the catalog-generator target name, which the
// executable and the test target both depend on.
let catalogGeneratorTargetName = "CatalogGenerator"

// Single source of truth for the executable name. `swift run
// generate-catalogs` and `scripts/generate-catalogs` both name it.
let generatorExecutableName = "generate-catalogs"

/// The GitHub organization URL base the swissarmyhammer-family dependency
/// resolves under.
///
/// `FoundationModelsSkills` is wired as a *remote* dependency (`main` branch),
/// never a local `path:` one, matching the family convention. Thus this
/// repository's CI can use the family's shared `swift-ci.yaml` reusable
/// workflow, which checks out only the calling repository -- a `path:`
/// dependency on a sibling checkout would not exist there.
let swissArmyHammerOrg = "git@github.com:swissarmyhammer/"

// Single source of truth for the client package, whose name is also the name
// of the product this package reads.
let clientPackageName = "FoundationModelsSkills"

/// The `swissarmyhammer-skills` marketplace package definition.
///
/// The repository is a skill marketplace, not a library: the product of this
/// repository is the `skills/` folder that `FoundationModelsSkills` reads as
/// one layer root (marketplace.md 3.2). Thus the package declares no library
/// product.
///
/// It declares three targets:
///
/// - `CatalogGenerator`, which writes the catalogs of the repository from the
///   skill folders (marketplace.md 3.3). Nobody edits a catalog by hand.
/// - `generate-catalogs`, the executable that runs the generator.
///   `scripts/generate-catalogs` is the wrapper a person calls.
/// - The test target, which is the repository's test harness: it builds a
///   `SkillsRegistry` over `skills/`, holds the library to the validation rules
///   the client applies at run time, and holds each committed catalog equal to
///   the generator output (marketplace.md 3.6).
let package = Package(
    name: "SkillsMarketplace",
    // macOS 27+, no pre-27 fallback: the floor `FoundationModelsSkills`
    // declares, inherited here because the test target depends on it.
    platforms: [
        .macOS("27.0"),
    ],
    products: [
        // The catalog generator, which a person runs through
        // `scripts/generate-catalogs`.
        .executable(name: generatorExecutableName, targets: [generatorExecutableName]),
    ],
    dependencies: [
        // The client this marketplace ships skills for. The test harness uses
        // its `SkillsRegistry` and its diagnostics, thus the repository is
        // checked with the same validator the host applies. The generator uses
        // the same registry to read the library, thus a catalog names the
        // skills the client loads.
        .package(url: "\(swissArmyHammerOrg)\(clientPackageName).git", branch: "main"),
    ],
    targets: [
        .target(
            name: catalogGeneratorTargetName,
            dependencies: [
                .product(name: clientPackageName, package: clientPackageName),
            ]
        ),
        .executableTarget(
            name: generatorExecutableName,
            dependencies: [
                .byName(name: catalogGeneratorTargetName),
            ]
        ),
        .testTarget(
            name: testTargetName,
            dependencies: [
                .product(name: clientPackageName, package: clientPackageName),
                .byName(name: catalogGeneratorTargetName),
            ]
        ),
    ]
)

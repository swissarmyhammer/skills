// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Single source of truth for the test-target name -- avoids repeating the
// literal across the target and its dependency list below.
let testTargetName = "SkillsMarketplaceTests"

/// The GitHub organization URL base the swissarmyhammer-family dependency
/// resolves under.
///
/// `FoundationModelsSkills` is wired as a *remote* dependency (`main` branch),
/// never a local `path:` one, matching the family convention. Thus this
/// repository's CI can use the family's shared `swift-ci.yaml` reusable
/// workflow, which checks out only the calling repository -- a `path:`
/// dependency on a sibling checkout would not exist there.
let swissArmyHammerOrg = "git@github.com:swissarmyhammer/"

/// The `swissarmyhammer-skills` marketplace package definition.
///
/// The repository is a skill marketplace, not a library: the product of this
/// repository is the `skills/` folder that `FoundationModelsSkills` reads as
/// one layer root (marketplace.md 3.2). Thus the package declares no library
/// product and no source target. It declares one test target, which is the
/// repository's test harness: it builds a `SkillsRegistry` over `skills/` and
/// holds the library to the validation rules the client applies at run time
/// (marketplace.md 3.6).
let package = Package(
    name: "SkillsMarketplace",
    // macOS 27+, no pre-27 fallback: the floor `FoundationModelsSkills`
    // declares, inherited here because the test target depends on it.
    platforms: [
        .macOS("27.0"),
    ],
    dependencies: [
        // The client this marketplace ships skills for. The test harness uses
        // its `SkillsRegistry` and its diagnostics, thus the repository is
        // checked with the same validator the host applies.
        .package(url: "\(swissArmyHammerOrg)FoundationModelsSkills.git", branch: "main"),
    ],
    targets: [
        .testTarget(
            name: testTargetName,
            dependencies: [
                .product(name: "FoundationModelsSkills", package: "FoundationModelsSkills"),
            ]
        ),
    ]
)

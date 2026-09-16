/// The state of the repository that the release tool cannot read by itself.
///
/// The tool writes files, and it never starts a program: this repository has no
/// git library, and product code here does not start `git`. Thus the two facts
/// that come from git and from the test runner arrive as values, and
/// `scripts/release` is what reads them from the host.
///
/// A caller must give the true state. A caller that says `clean` over a dirty
/// tree gets the release it asked for, in the same way that a person who edits
/// a catalog by hand gets the catalog they wrote.
public struct ReleasePreflight: Sendable, Equatable {
    /// Whether the working tree holds a change that is not committed.
    public enum WorkingTree: String, Sendable, Equatable {
        /// Every change of the tree is committed.
        case clean

        /// The tree holds a change that is not committed.
        case dirty
    }

    /// How the test suite of the repository ended.
    public enum TestRun: String, Sendable, Equatable {
        /// Every test passed.
        case passed

        /// A test failed.
        case failed
    }

    /// The state of the working tree.
    public let workingTree: WorkingTree

    /// The result of the test run.
    public let testRun: TestRun

    /// Makes the state of one repository.
    ///
    /// - Parameters:
    ///   - workingTree: The state of the working tree.
    ///   - testRun: The result of the test run.
    public init(workingTree: WorkingTree, testRun: TestRun) {
        self.workingTree = workingTree
        self.testRun = testRun
    }
}

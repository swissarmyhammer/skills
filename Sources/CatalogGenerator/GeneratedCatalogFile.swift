import Foundation

/// One file that ``CatalogGenerator`` writes.
///
/// The generator gives the bytes before it writes them, thus a test can hold
/// the committed file equal to the bytes without a write of its own.
public struct GeneratedCatalogFile: Sendable, Hashable {
    /// The path of the file, relative to the repository root.
    public let path: String

    /// The bytes of the file, which end with a line break.
    public let contents: Data

    /// Makes the record of one generated file.
    ///
    /// - Parameters:
    ///   - path: The path of the file, relative to the repository root.
    ///   - contents: The bytes of the file.
    internal init(path: String, contents: Data) {
        self.path = path
        self.contents = contents
    }
}

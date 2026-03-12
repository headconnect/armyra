import Foundation

public extension ProjectPackageStore {
    static func encodeString(_ package: ProjectPackage) throws -> String {
        let data = try encode(package)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return string
    }

    static func suggestedFileName(for package: ProjectPackage) -> String {
        let sanitized = package.projectName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        let stem = sanitized.isEmpty ? "armyra-project" : sanitized
        return "\(stem).\(fileExtension)"
    }
}
import Foundation

public enum ProjectPackageStore {
    public static let fileExtension = "armyrafield"

    public static func encode(_ package: ProjectPackage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    public static func decode(_ data: Data) throws -> ProjectPackage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ProjectPackage.self, from: data)
    }
}
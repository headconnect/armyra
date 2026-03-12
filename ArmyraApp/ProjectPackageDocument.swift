import SwiftUI
import UniformTypeIdentifiers
import ArmyraCore

extension UTType {
    static let armyraField = UTType(exportedAs: "io.headconnect.armyra.field-package")
}

struct ProjectPackageDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.armyraField, .json] }
    static var writableContentTypes: [UTType] { [.armyraField] }

    var project: ProjectPackage

    init(project: ProjectPackage) {
        self.project = project
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        project = try ProjectPackageStore.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try ProjectPackageStore.encode(project))
    }
}

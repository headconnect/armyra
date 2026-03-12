import Foundation
import ArmyraCore

protocol VenueTrackingAssetStore {
    func save(_ asset: VenueTrackingAssetRecord, payload: Data?)
    func latestAsset(for venueScanID: UUID) -> VenueTrackingAssetRecord?
    func payload(for asset: VenueTrackingAssetRecord) -> Data?
}

enum DefaultVenueTrackingAssetStoreFactory {
    static func make() -> VenueTrackingAssetStore {
        (try? FileBackedVenueTrackingAssetStore()) ?? InMemoryVenueTrackingAssetStore()
    }
}

final class InMemoryVenueTrackingAssetStore: VenueTrackingAssetStore {
    private var assetsByVenue: [UUID: [VenueTrackingAssetRecord]] = [:]
    private var payloadsByAssetID: [UUID: Data] = [:]

    func save(_ asset: VenueTrackingAssetRecord, payload: Data?) {
        assetsByVenue[asset.venueScanID, default: []].append(asset)
        if let payload {
            payloadsByAssetID[asset.id] = payload
        }
    }

    func latestAsset(for venueScanID: UUID) -> VenueTrackingAssetRecord? {
        assetsByVenue[venueScanID]?.sorted { $0.createdAt > $1.createdAt }.first
    }

    func payload(for asset: VenueTrackingAssetRecord) -> Data? {
        payloadsByAssetID[asset.id]
    }
}

final class FileBackedVenueTrackingAssetStore: VenueTrackingAssetStore {
    private let fileManager: FileManager
    private let rootDirectory: URL
    private let indexURL: URL
    private var assetsByVenue: [UUID: [VenueTrackingAssetRecord]] = [:]

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager

        let applicationSupport = try Self.applicationSupportDirectory(fileManager: fileManager)
        rootDirectory = applicationSupport.appendingPathComponent("VenueTrackingAssets", isDirectory: true)
        indexURL = rootDirectory.appendingPathComponent("index.json")

        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true, attributes: nil)
        try loadIndex()
    }

    func save(_ asset: VenueTrackingAssetRecord, payload: Data?) {
        assetsByVenue[asset.venueScanID, default: []].append(asset)

        if let payload {
            let payloadURL = payloadURL(for: asset)
            try? payload.write(to: payloadURL, options: .atomic)
        }

        try? persistIndex()
    }

    func latestAsset(for venueScanID: UUID) -> VenueTrackingAssetRecord? {
        assetsByVenue[venueScanID]?.sorted { $0.createdAt > $1.createdAt }.first
    }

    func payload(for asset: VenueTrackingAssetRecord) -> Data? {
        try? Data(contentsOf: payloadURL(for: asset))
    }

    private func payloadURL(for asset: VenueTrackingAssetRecord) -> URL {
        rootDirectory.appendingPathComponent("\(asset.id.uuidString.lowercased()).bin")
    }

    private func loadIndex() throws {
        guard fileManager.fileExists(atPath: indexURL.path) else { return }
        let data = try Data(contentsOf: indexURL)
        let records = try JSONDecoder().decode([VenueTrackingAssetRecord].self, from: data)
        assetsByVenue = Dictionary(grouping: records, by: \.venueScanID)
    }

    private func persistIndex() throws {
        let records = assetsByVenue.values.flatMap { $0 }.sorted { $0.createdAt < $1.createdAt }
        let data = try JSONEncoder().encode(records)
        try data.write(to: indexURL, options: .atomic)
    }

    private static func applicationSupportDirectory(fileManager: FileManager) throws -> URL {
        guard let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let appDirectory = directory.appendingPathComponent("Armyra", isDirectory: true)
        try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        return appDirectory
    }
}

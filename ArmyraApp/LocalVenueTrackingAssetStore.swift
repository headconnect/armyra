import Foundation
import ArmyraCore

protocol VenueTrackingAssetStore {
    func save(_ asset: VenueTrackingAssetRecord)
    func latestAsset(for venueScanID: UUID) -> VenueTrackingAssetRecord?
}

final class InMemoryVenueTrackingAssetStore: VenueTrackingAssetStore {
    private var assetsByVenue: [UUID: [VenueTrackingAssetRecord]] = [:]

    func save(_ asset: VenueTrackingAssetRecord) {
        assetsByVenue[asset.venueScanID, default: []].append(asset)
    }

    func latestAsset(for venueScanID: UUID) -> VenueTrackingAssetRecord? {
        assetsByVenue[venueScanID]?.sorted { $0.createdAt > $1.createdAt }.first
    }
}

//
//  Memory.swift
//  AR Journal Memory
//
//  Memory data model with persistence
//

import Foundation
import RealityKit
import UIKit
import CoreLocation

struct Memory: Codable, Identifiable {
    var id: UUID
    var title: String
    var description: String
    var position: MemoryPosition
    var color: MemoryColor
    var dateCreated: Date
    var locationCoordinate: LocationCoordinate? // GPS location
    var worldMapData: Data? // ARWorldMap data for relocation
    
    init(id: UUID = UUID(), title: String, description: String, position: SIMD3<Float>, color: MemoryColor, location: CLLocationCoordinate2D? = nil, worldMapData: Data? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.position = MemoryPosition(x: position.x, y: position.y, z: position.z)
        self.color = color
        self.dateCreated = Date()
        self.locationCoordinate = location != nil ? LocationCoordinate(latitude: location!.latitude, longitude: location!.longitude) : nil
        self.worldMapData = worldMapData
    }
    
    var simdPosition: SIMD3<Float> {
        SIMD3<Float>(position.x, position.y, position.z)
    }
    
    var clLocation: CLLocationCoordinate2D? {
        guard let loc = locationCoordinate else { return nil }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }
}

// Codable wrapper for SIMD3<Float>
struct MemoryPosition: Codable {
    var x: Float
    var y: Float
    var z: Float
}

// Codable wrapper for CLLocationCoordinate2D
struct LocationCoordinate: Codable {
    var latitude: Double
    var longitude: Double
}

// Colorful treasure box colors
enum MemoryColor: String, Codable, CaseIterable {
    case gold = "Gold"
    case ruby = "Ruby"
    case emerald = "Emerald"
    case sapphire = "Sapphire"
    case amethyst = "Amethyst"
    case coral = "Coral"
    
    var uiColor: UIColor {
        switch self {
        case .gold:
            return UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        case .ruby:
            return UIColor(red: 0.88, green: 0.07, blue: 0.37, alpha: 1.0)
        case .emerald:
            return UIColor(red: 0.31, green: 0.78, blue: 0.47, alpha: 1.0)
        case .sapphire:
            return UIColor(red: 0.06, green: 0.32, blue: 0.73, alpha: 1.0)
        case .amethyst:
            return UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
        case .coral:
            return UIColor(red: 1.0, green: 0.5, blue: 0.31, alpha: 1.0)
        }
    }
    
    static func random() -> MemoryColor {
        return allCases.randomElement() ?? .gold
    }
}

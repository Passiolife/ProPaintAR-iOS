//
//  Paint.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 12/05/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//
// swiftlint:disable line_length

import RemodelAR
import UIKit

protocol Paint {
    var id: String { get set }
    var name: String { get set }
    var color: UIColor { get set }
    var texture: UIImage? { get set }
    var thumbnail: Thumbnail? { get set }
    var code: String? { get set }
    var sizes: [ContainerSize] { get set }
    var secondaryColors: [Paint] { get set }
}

protocol PaintPickerDelegate: AnyObject {
    func paintPickerView(_ paintPicker: PaintPickerView, didSelectPaintAt indexPath: IndexPath, primary paint: Paint)
    func paintPickerView(_ paintPicker: PaintPickerView, didSelectPaintAt indexPath: IndexPath, secondary paint: Paint)
    func paintPickerViewDidScroll(_ paintPicker: PaintPickerView, primary paint: Paint)
    func paintPickerViewDidScroll(_ paintPicker: PaintPickerView, secondary paint: Paint)
    func secondaryPaintPickerView(_ paintPicker: PaintPickerView, dismiss: Bool)
}

protocol PaintItemShadow {
    var shadowColor: CGColor? { get set }
    var shadowOpacity: Float { get set }
    var shadowRadius: CGFloat { get set }
    var shadowOffset: CGSize { get set }
}

protocol PaintPickerDataSource: AnyObject {
    func paints(for paintPicker: PaintPickerView) -> [Paint]

    // image methods
    func primaryPaintPickerView(_ paintPicker: PaintPickerView, imageFor indexPath: IndexPath) -> UIImage?
    func secondaryPaintPickerView(_ paintPicker: PaintPickerView, imageFor indexPath: IndexPath, primaryPaint index: Int) -> UIImage?
    
    // border methods
    func primaryPaintPickerView(_ paintPicker: PaintPickerView, borderColorFor indexPath: IndexPath) -> CGColor
    func secondaryPaintPickerView(_ paintPicker: PaintPickerView, borderColorFor indexPath: IndexPath, primaryPaint index: Int) -> CGColor
    func primaryPaintPickerView(_ paintPicker: PaintPickerView, borderWidthFor indexPath: IndexPath) -> CGFloat
    func secondaryPaintPickerView(_ paintPicker: PaintPickerView, borderWidthFor indexPath: IndexPath, primaryPaint index: Int) -> CGFloat

    func paintPickerView(_ paintPicker: PaintPickerView, cornerRadiusFor indexPath: IndexPath) -> CGFloat
    func paintPickerView(_ paintPicker: PaintPickerView, shadowFor indexPath: IndexPath) -> PaintItemShadow?
}

struct Thumbnail {
    var image: UIImage?
    var url: String?
}

public struct ProPaint {
    public let id: String
    public let name: String
    public let color: UIColor
    public let userColor: Bool
    public let sizes: [ContainerSize]
    
    public init(
        wallPaint: WallPaint,
        sizes: [ContainerSize]
    ) {
        self.id = wallPaint.id
        self.name = wallPaint.name
        self.color = wallPaint.color
        self.userColor = wallPaint.userColor
        self.sizes = sizes
    }
    
    public init(
        id: String,
        name: String,
        color: UIColor,
        userColor: Bool = true,
        sizes: [ContainerSize]
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.userColor = userColor
        self.sizes = sizes
    }
}

public struct ProWallInfo {
    public let id: String
    public let area: AreaInfo
    public let paint: ProPaint
    public let surfaceType: SurfaceType
}

public enum SheenType: Codable {
    case matte(String)
    case eggshell(String)
    case satin(String)
    case semigloss(String)
    
    var index: Int {
        switch self {
        case .matte: return 0
        case .eggshell: return 1
        case .satin: return 2
        case .semigloss: return 3
        }
    }
    
    var asin: String {
        switch self {
        case .matte(let string):
            return string
            
        case .eggshell(let string):
            return string
            
        case .satin(let string):
            return string
            
        case .semigloss(let string):
            return string
        }
    }
}

extension SheenType {
    private enum CodingKeys: String, CodingKey {
        case matte
        case eggshell
        case satin
        case semigloss
    }
    
    enum PostTypeCodingError: Error {
        case decoding(String)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(String.self, forKey: .matte) {
            self = .matte(value)
            return
        }
        if let value = try? values.decode(String.self, forKey: .eggshell) {
            self = .eggshell(value)
            return
        }
        if let value = try? values.decode(String.self, forKey: .satin) {
            self = .satin(value)
            return
        }
        if let value = try? values.decode(String.self, forKey: .semigloss) {
            self = .semigloss(value)
            return
        }
        throw PostTypeCodingError.decoding("Whoops! \(dump(values))")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .matte(let asin):
            try container.encode(asin, forKey: .matte)
            
        case .eggshell(let asin):
            try container.encode(asin, forKey: .eggshell)
            
        case .satin(let asin):
            try container.encode(asin, forKey: .satin)
            
        case .semigloss(let asin):
            try container.encode(asin, forKey: .semigloss)
        }
    }
}

public enum ContainerSize: Codable {
    case gallon([SheenType])
    case sample([SheenType])
    
    var sheens: [SheenType] {
        switch self {
        case .gallon(let array):
            return array.sorted(by: { $0.index < $1.index })
            
        case .sample(let array):
            return array.sorted(by: { $0.index < $1.index })
        }
    }
    
    var index: Int {
        switch self {
        case .gallon: return 0
        case .sample: return 1
        }
    }
}

extension ContainerSize {
    private enum CodingKeys: String, CodingKey {
        case gallon
        case sample
    }
    
    enum PostTypeCodingError: Error {
        case decoding(String)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode([SheenType].self, forKey: .gallon) {
            self = .gallon(value)
            return
        }
        if let value = try? values.decode([SheenType].self, forKey: .sample) {
            self = .sample(value)
            return
        }
        throw PostTypeCodingError.decoding("Whoops! \(dump(values))")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .gallon(let sheens):
            try container.encode(sheens, forKey: .gallon)
            
        case .sample(let sheens):
            try container.encode(sheens, forKey: .sample)
        }
    }
}

//
//  ResponseModel.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 5/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

struct ResponseModel: Codable {
    var id: String
    var name: String
    var color: String
    var code: String?
    var texture: String?
    var sizes: [ContainerSize]?
    var secondaryColors: [ResponseModel]?
}

struct AmazonResponseModel: Codable {
    var id: String
    var name: String
    var color: String
    var code: String?
    var sizes: [ContainerSize]
    var secondaryColors: [AmazonResponseModel]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case code
        case sizes
        case secondaryColors
    }
    
    init(id: String, name: String, color: String, code: String, sizes: [ContainerSize]) {
        self.id = id
        self.name = name
        self.color = color
        self.code = code
        self.sizes = sizes
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? values.decode(String.self, forKey: .code) {
            code = value
        }
        if let value = try? values.decode([AmazonResponseModel].self,
                                          forKey: .secondaryColors) {
            secondaryColors = value
        }
        name = try values.decode(String.self, forKey: .name)
        color = try values.decode(String.self, forKey: .color)
        id = try values.decode(String.self, forKey: .id)
        sizes = try values.decode([ContainerSize].self, forKey: .sizes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(code, forKey: .code)
        try container.encode(id, forKey: .id)
        try container.encode(sizes, forKey: .sizes)
        try container.encode(secondaryColors, forKey: .secondaryColors)
    }
}

extension Array where Element == ResponseModel {
    func convertToPaintModel() -> [Paint] {
        self.compactMap { color -> Paint? in
            var texture: UIImage?
            if let textureName = color.texture {
                texture = UIImage(named: textureName)
            }
            var subColors: [PaintModel] = []
            if let secondaryColor = color.secondaryColors {
                subColors = secondaryColor.map {
                    PaintModel(id: $0.id,
                               name: $0.name,
                               color: UIColor(hex: $0.color),
                               // swiftlint:disable:next force_unwrapping
                               texture: $0.texture == nil ? nil : UIImage(named: $0.texture!),
                               code: $0.code,
                               sizes: [],
                               secondaryColors: [])
                }
            }
            
            return PaintModel(id: color.id,
                              name: color.name,
                              color: UIColor(hex: color.color),
                              texture: texture,
                              code: color.code,
                              thumbnail: nil,
                              sizes: [],
                              secondaryColors: subColors)
        }
    }
}

extension Array where Element == AmazonResponseModel {
    func convertToPaintModel() -> [Paint] {
        self.compactMap { color -> Paint? in
            var subColors: [PaintModel] = []
            if let secondaryColor = color.secondaryColors {
                subColors = secondaryColor.map {
                    PaintModel(id: $0.id,
                               name: $0.name,
                               color: UIColor(hex: $0.color),
                               code: $0.code,
                               sizes: $0.sizes,
                               secondaryColors: [])
                }
            }
            
            return PaintModel(id: color.id,
                              name: color.name,
                              color: UIColor(hex: color.color),
                              texture: nil,
                              code: color.code,
                              thumbnail: nil,
                              sizes: [],
                              secondaryColors: subColors)
        }
    }
}

extension Array where Element == BMDatum {
    func convertToPaintModel() -> [Paint] {
        enumerated().map { index, color in
            var subColors: [PaintModel] = []
            subColors = color.colors.map {
                PaintModel(id: $0.number,
                           name: $0.name,
                           color: UIColor(hex: $0.hex),
                           code: $0.number,
                           sizes: [],
                           secondaryColors: [])
            }
            
            return PaintModel(id: "\(index)",
                              name: color.headerTitle,
                              color: UIColor(hex: color.backgroundColorData.colors[0].hex),
                              texture: nil,
                              code: "\(index)",
                              thumbnail: nil,
                              sizes: [],
                              secondaryColors: subColors)
        }
    }
}

extension Array where Element == KilzExpression {
    func convertToPaintModel() -> [Paint] {
        enumerated().map { index, color in
            var subColors: [PaintModel] = []
            subColors = color.familyAll.map {
                PaintModel(id: $0.code,
                           name: $0.color,
                           color: UIColor(hex: $0.hex),
                           code: $0.code,
                           sizes: [],
                           secondaryColors: [])
            }
            
            return PaintModel(id: "\(index)",
                              name: color.familyName,
                              color: subColors[0].color,
                              texture: nil,
                              code: "\(index)",
                              thumbnail: nil,
                              sizes: [],
                              secondaryColors: subColors)
        }
    }
}

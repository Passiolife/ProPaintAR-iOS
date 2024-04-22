//
//  BenjaminMooreData.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/7/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

struct BMData: Codable {
    let colorData: BMColorData

    enum CodingKeys: String, CodingKey {
        case colorData = "color_data"
    }
}

// MARK: - ColorData
struct BMColorData: Codable {
    let data: [BMDatum]
}

// MARK: - Datum
struct BMDatum: Codable {
    let colors: [BMColor]
    let backgroundColorData: BMBackgroundColorData
    let headerTitle: String

    enum CodingKeys: String, CodingKey {
        case colors
        case backgroundColorData = "background_color_data"
        case headerTitle
    }
}

// MARK: - BackgroundColorData
struct BMBackgroundColorData: Codable {
    let colors: [BMColor]
}

// MARK: - Color
struct BMColor: Codable {
    let name, number, hex: String
}

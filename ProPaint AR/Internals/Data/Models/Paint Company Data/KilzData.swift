//
//  KilzData.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/7/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

struct KilzData: Codable {
    let colorFamilies: KilzColorFamilies
}

// MARK: - ColorFamilies
struct KilzColorFamilies: Codable {
    let expressions: [KilzExpression]

    enum CodingKeys: String, CodingKey {
        case expressions = "Expressions"
    }
}

// MARK: - Expression
struct KilzExpression: Codable {
    let familyName: String
    let familyAll: [KilzFamilyAll]
}

// MARK: - FamilyAll
struct KilzFamilyAll: Codable {
    let code, color, hex: String
}

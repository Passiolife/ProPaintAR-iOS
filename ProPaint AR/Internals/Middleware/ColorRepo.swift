//
//  ColorRepo.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/28/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

protocol ColorRepo {
    var colors: [Paint] { get }
    var colorsPublished: Published<[Paint]> { get }
    var colorsPublisher: Published<[Paint]>.Publisher { get }
    
    func updateColors()
    func sizes(id: String) -> [ContainerSize]?
}

final class ColorRepoImpl: ColorRepo {
    @Published var colors = [Paint]()
    var colorsPublished: Published<[Paint]> { _colors }
    var colorsPublisher: Published<[Paint]>.Publisher { $colors }
    
    private let colorAPI: ColorAPI
    private var lastUpdatedColors: Date?
    
    init(colorAPI: ColorAPI) {
        self.colorAPI = colorAPI
        updateColors()
    }
    
    func sizes(id: String) -> [ContainerSize]? {
        for color in colors {
            if let subColor = color.secondaryColors.first(where: { $0.id == id }) {
                return subColor.sizes
            }
        }
        return nil
    }
    
    func updateColors() {
        if let lastUpdated = lastUpdatedColors,
           Date().timeIntervalSince(lastUpdated) > Date.days(1) {
            return
        }

        colorAPI.fetchColors { [weak self] colors, error in
            if error != nil {
                return
            }

            self?.lastUpdatedColors = Date()
            self?.colors = colors
        }
    }
}

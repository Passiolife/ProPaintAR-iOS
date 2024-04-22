//
//  ColorAPI.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/28/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

protocol ColorAPI {
    func fetchColors(callback: @escaping ([Paint], Error?) -> Void)
}

class ColorAPIMock: ColorAPI {
    func fetchColors(callback: @escaping ([Paint], Error?) -> Void) {
        let passio = fetchPassioColors()
//        let kilzAmazon = fetchKilzAmazonColors()
        callback(passio, nil)
        
        // Keep these around, we might use these for custom implementations for clients.
//        let jazeera = fetchJazeeraColors()
//        let benjaminMoore = fetchBenjaminMooreColors()
//        let behr = fetchBehrColors()
//        let kilz = fetchKilzColors()
        
//        callback(passio + jazeera + benjaminMoore + behr + kilz, nil)
    }
    
    func fetchJazeeraColors() -> [Paint] {
        guard let colorPath = Bundle.main.path(forResource: "Jazeera Color Deck", ofType: "json")
        else { return [] }

        var paints: [Paint] = []

        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: colorPath), options: .uncached)
            let model = try jsonDecoder.decode([ResponseModel].self, from: jsonData)
            paints = model.convertToPaintModel()
        } catch {
            debugPrint("error: \(error)")
        }

        return paints
    }
    
    func fetchPassioColors() -> [Paint] {
        guard let colorPath = Bundle.main.path(forResource: "Passio Color Deck", ofType: "json")
        else { return [] }

        var paints: [Paint] = []

        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: colorPath), options: .uncached)
            let model = try jsonDecoder.decode([ResponseModel].self, from: jsonData)
            paints = model.convertToPaintModel()
        } catch {
            debugPrint("error: \(error)")
        }

        return paints
    }
    
    func fetchBenjaminMooreColors() -> [Paint] {
        guard let colorPath = Bundle.main.path(forResource: "Benjamin Moore Color Deck",
                                               ofType: "json")
        else { return [] }
        
        var paints: [Paint] = []
        
        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: colorPath), options: .uncached)
            let model = try jsonDecoder.decode(BMData.self, from: jsonData)
            paints = model.colorData.data.convertToPaintModel()
        } catch {
            debugPrint("error: \(error)")
        }
        
        return paints
    }
    
    func fetchBehrColors() -> [Paint] {
        guard let colorPath = Bundle.main.path(forResource: "Behr Color Deck",
                                               ofType: "json")
        else { return [] }
        
        var paints: [Paint] = []
        
        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: colorPath), options: .uncached)
            let model = try jsonDecoder.decode([ResponseModel].self, from: jsonData)
            paints = model.convertToPaintModel()
        } catch {
            debugPrint("error: \(error)")
        }
        
        return paints
    }
    
    func fetchKilzColors() -> [Paint] {
        guard let colorPath = Bundle.main.path(forResource: "Kilz Color Deck",
                                               ofType: "json")
        else { return [] }
        
        var paints: [Paint] = []
        
        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: colorPath), options: .uncached)
            let model = try jsonDecoder.decode(KilzData.self, from: jsonData)
            paints = model.colorFamilies.expressions.convertToPaintModel()
        } catch {
            debugPrint("error: \(error)")
        }
        
        return paints
    }
    
    func fetchKilzAmazonColors() -> [Paint] {
        guard let colorPath = Bundle.main.path(forResource: "Kilz Amazon Color Deck",
                                               ofType: "json")
        else { return [] }
        
        var paints: [Paint] = []
        
        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: colorPath), options: .uncached)
            let model = try jsonDecoder.decode([AmazonResponseModel].self, from: jsonData)
            paints = model.convertToPaintModel()
        } catch {
            debugPrint("error: \(error)")
        }
        
        return paints
    }
}

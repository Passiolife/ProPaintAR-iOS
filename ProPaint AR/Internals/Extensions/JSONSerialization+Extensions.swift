//
//  JSONSerialization+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/30/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

extension JSONSerialization {
    static func loadJSON(withFilename filename: String) throws -> Any? {
        let fm = FileManager.default
        let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        if let url = urls.first {
            var fileURL = url.appendingPathComponent(filename)
            fileURL = fileURL.appendingPathExtension("json")
            let data = try Data(contentsOf: fileURL)
            let jsonObject = try JSONSerialization.jsonObject(
                with: data,
                options: [.mutableContainers, .mutableLeaves]
            )
            return jsonObject
        }
        return nil
    }
    
    static func saveJSON(jsonObject: Any, toFilename filename: String) throws -> Bool {
        let fm = FileManager.default
        let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        if let url = urls.first {
            var fileURL = url.appendingPathComponent(filename)
            fileURL = fileURL.appendingPathExtension("json")
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            try data.write(to: fileURL, options: [.atomicWrite])
            return true
        }
        
        return false
    }
    
    static func deleteJSON(filename: String) {
        let fm = FileManager.default
        let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        if let url = urls.first {
            var fileURL = url.appendingPathComponent(filename)
            fileURL = fileURL.appendingPathExtension("json")
            try? fm.removeItem(at: fileURL)
        }
    }
}

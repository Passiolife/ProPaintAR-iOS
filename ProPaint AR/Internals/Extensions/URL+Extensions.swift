//
//  URL+Extensions.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/9/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

extension URL {
    /**
     Creates a new URL by adding the given query parameters.
     @param parametersDictionary The query parameter dictionary to add.
     @return A new URL.
    */
    func appendingQueryParameters(_ parametersDictionary: [String: String]) -> URL {
        let URLString = String(format: "%@?%@",
                               absoluteString,
                               parametersDictionary.queryParameters)
        
        guard let url = URL(string: URLString)
        else { return self }
        
        return url
    }
}

//
//  Dictionary+Extensions.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/9/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

protocol URLQueryParameterStringConvertible {
    var queryParameters: String { get }
}

extension Dictionary: URLQueryParameterStringConvertible {
    /**
     This computed property returns a query parameters string from the given NSDictionary. For
     example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
     string will be @"day=Tuesday&month=January".
     @return The computed parameters string.
    */
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            if let part1 = String(describing: key)
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let part2 = String(describing: value)
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                let part = String(format: "%@=%@", part1, part2)
                parts.append(part as String)
            }
        }
        return parts.joined(separator: "&")
    }
}

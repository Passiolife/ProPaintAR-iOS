//
//  Date+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/26/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

extension Date {
    static func days(_ time: Double) -> TimeInterval {
        time * hours(24)
    }
    
    static func hours(_ time: Double) -> TimeInterval {
        time * minutes(60)
    }
    
    static func minutes(_ time: Double) -> TimeInterval {
        time * 60
    }
}

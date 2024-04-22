//
//  Analytics.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/21/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import Mixpanel

enum Analytics {
    private static var lastEvent = ""
    
    public static func trackEvent(name: String, parameters: [String: MixpanelType]? = nil) {
        guard lastEvent != name
        else { return }
        
        lastEvent = name
        Mixpanel.mainInstance().track(event: name, properties: parameters)
    }
    
    public static func trackScreen(name: String, parameters: [String: MixpanelType]? = nil) {
        trackEvent(name: name, parameters: parameters)
    }
    
    public static func time(event: String) {
        Mixpanel.mainInstance().time(event: event)
    }
}

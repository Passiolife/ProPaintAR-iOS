//
//  Trackable.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/14/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//
 
import Foundation
import Mixpanel
import UIKit

protocol Trackable {
    func trackScreen(name: String, parameters: [String: Any]?)
    func trackEvent(name: String, parameters: [String: Any]?)
    func trackTime(event: String)
}

extension Trackable {
    func configureAnalytics() {}
    
    private func trackMixpanel(name: String, parameters: [String: Any]? = nil) {
        var parametersValidated: [String: MixpanelType]?
        if let parameters = parameters {
            parametersValidated = [String: MixpanelType]()
            for (key, value) in parameters {
                if let valueValidated = value as? MixpanelType {
                    parametersValidated?[key] = valueValidated
                }
            }
        }
        
        Analytics.trackEvent(name: name, parameters: parametersValidated)
    }
    
    public func trackScreen(name: String, parameters: [String: Any]? = nil) {
        trackMixpanel(name: name, parameters: parameters)
    }
    
    public func trackEvent(name: String, parameters: [String: Any]? = nil) {
        trackMixpanel(name: name, parameters: parameters)
    }
    
    public func trackTime(event: String) {
        Analytics.time(event: event)
    }
}

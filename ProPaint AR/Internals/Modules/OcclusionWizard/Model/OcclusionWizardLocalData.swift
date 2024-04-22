//
//  OcclusionWizardLocalData.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/19/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

extension OcclusionWizardViewController {
    class LocalData {
        @Published private(set) final var data: ViewModel
        
        var colors: [UIColor] {
            get {
                data.colors
            }
            set {
                data.colors = newValue
            }
        }
        
        var threshold: Float {
            get {
                data.threshold
            }
            set {
                data.threshold = newValue
            }
        }
        
        var state: OcclusionState {
            get {
                data.state
            }
            set {
                data.state = newValue
            }
        }
        
        init(data: OcclusionStateInfo) {
            self.data = ViewModel(data: data)
        }
        
        func updateViewState(state: OcclusionState) {
            var dataCopy = data
            dataCopy.state = state
            data = dataCopy
        }
        
        func addOcclusionColor(color: UIColor) {
            guard data.colors.count < 3,
                  state == .pickingColors
            else { return }
            
            var dataCopy = data
            dataCopy.colors.append(color)
            data = dataCopy
        }
        
        func setOcclusionState(state: OcclusionState) {
            var dataCopy = data
            dataCopy.state = state
            data = dataCopy
        }
        
        func setOcclusionThreshold(threshold: Float) {
            var dataCopy = data
            dataCopy.threshold = threshold
            data = dataCopy
        }
        
        func reset() {
            var dataCopy = data
            dataCopy.state = .start
            dataCopy.colors.removeAll()
            dataCopy.threshold = 10
            data = dataCopy
        }
    }
}

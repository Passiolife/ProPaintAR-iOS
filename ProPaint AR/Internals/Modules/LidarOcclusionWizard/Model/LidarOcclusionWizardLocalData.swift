//
//  LidarOcclusionWizardLocalData.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 4/27/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

extension LidarOcclusionWizardViewController {
    class LocalData {
        @Published private(set) final var threshold: Float
        @Published private(set) final var isScanning: Bool
        public let resetLidarOcclusions = PassthroughSubject<Void, Never>()
        
        init(threshold: Float) {
            self.threshold = threshold
            self.isScanning = false
        }
        
        func setThreshold(threshold: Float) {
            self.threshold = threshold
        }
        
        func setScanState(isScanning: Bool) {
            self.isScanning = isScanning
        }
    }
}

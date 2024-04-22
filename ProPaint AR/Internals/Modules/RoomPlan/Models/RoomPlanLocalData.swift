//
//  RoomPlanLocalData.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 3/1/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

@available(iOS 16, *)
extension RoomPlanViewController {
    class LocalData {
        @Published private(set) final var data: ViewModel
        
        init() {
            data = ViewModel()
        }
             
        func setLidarOcclusionThreshold(threshold: Float) {
            data.lidarOcclusionThreshold = threshold
        }
        
        func updateOcclusionData(occlusionInfo: OcclusionStateInfo) {
            var dataCopy = data
            dataCopy.occlusionViewModel = occlusionInfo
            data = dataCopy
        }
               
        func reset() {
            var dataCopy = data
            dataCopy.occlusionViewModel.colors = []
            dataCopy.occlusionViewModel.threshold = 10
            dataCopy.occlusionViewModel.state = .start
            data = dataCopy
        }
    }
}

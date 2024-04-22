//
//  FloorplanLocalData.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/25/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

extension FloorplanViewController {
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

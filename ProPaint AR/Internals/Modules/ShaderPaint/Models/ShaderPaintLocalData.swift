//
//  ShaderPaintLocalData.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

extension ShaderPaintViewController {
    class LocalData {
        @Published private(set) final var data: ViewModel
        private var textColor = UIColor.text
        private var font = FontTheme.font(family: .SFProText,
                                          weight: .Medium,
                                          size: 16)
        private var icon = UIImage(named: "colorRange")
        
        var userHint: NSAttributedString {
            data.userHint(color: textColor, font: font, icon: icon)
        }
        
        init() {
            data = ViewModel()
        }
                
        func updateHintStyle(color: UIColor, font: UIFont, icon: UIImage?) {
            self.textColor = color
            self.font = font
            if let icon = icon {
                self.icon = icon
            }
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

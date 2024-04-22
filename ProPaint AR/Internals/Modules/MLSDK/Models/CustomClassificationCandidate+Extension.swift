//
//  CustomClassificationCandidate+Extension.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 1/26/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Foundation
import PassioRemodelAISDK

extension CustomClassificationCandidate {
    func toClassDetectionImp() -> ClassificationCandidateImp {
        ClassificationCandidateImp(passioID: self.passioID,
                                   confidence: self.confidence)
    }
}

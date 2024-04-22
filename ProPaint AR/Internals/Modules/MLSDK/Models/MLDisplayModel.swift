//
//  MLDisplayModel.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/6/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import PassioRemodelAISDK
import UIKit

struct MLDisplayModel {
    let objectID: String
    let description: String
    let confidence: Double
    let boundingBox: CGRect?
    let allResults: [TimeSeriesConfidenceCount]
    
    private var skipBackground: Bool {
        if objectID == "BKG0001" {
            if allResults.count > 1,
               confidence / 2 < allResults[1].totalConfidence,
               allResults[1].totalConfidence >= 2 {
                return true
            }
        }
        return false
    }
    
    var debugLines: [String] {
        allResults.compactMap({
            "\(passioIDDic[$0.candidate.passioID]?["en"] ?? $0.candidate.passioID) - \($0.totalConfidence.truncated(decimals: 1))"
        })
    }
    
    func displayResults(showConfidence: Bool = false) -> (topResult: String, alternates: String) {
        (topResult(showConfidence: showConfidence), alternateResults(showConfidence: showConfidence))
    }

    private func topResult(showConfidence: Bool = false) -> String {
        func createString(id: String, confidence: Double, showConfidence: Bool = false) -> String {
            let confidence = showConfidence ? " \(confidence.truncated(decimals: 1))" : ""
            if let dic = passioIDDic[id],
               let description = dic["en"] {
                return "\(description.capitalized)\(confidence)"
            }
            return "\(id.capitalized)\(confidence)"
        }
        
        if objectID == "BKG0001" {
            if skipBackground {
                let id = allResults[1].candidate.passioID
                let confidence = allResults[1].totalConfidence
                return createString(id: id, confidence: confidence, showConfidence: showConfidence)
            } else {
                return ""
            }
        } else {
            return createString(id: objectID, confidence: confidence, showConfidence: showConfidence)
        }
    }
    
    private func alternateResults(showConfidence: Bool = false) -> String {
        var output = [String]()
        let startIndex = skipBackground ? 2 : 1
        for index in startIndex..<allResults.count {
            let id = allResults[index].candidate.passioID
            if let dic = passioIDDic[id],
               let description = dic["en"],
               id != "BKG0001" {
                var addition = ""
                if showConfidence {
                    addition = " \(allResults[index].totalConfidence.truncated(decimals: 1))"
                }
                output.append(description + addition)
            }
        }
        return output.joined(separator: "\n")
    }
}

extension ModelType {
    var instructionText: String {
        switch self {
        case .abnormalities, .abnormalitiesSSD:
            return "Aim the camera at an abnormality to continue"
        case .environments:
            return "Step back and aim the camera at the entire room to continue"
        case .surfaces:
            return "Aim the camera at a surface to continue"
        }
    }
}

extension MLStateMachine.State {
    var currentResult: MLDisplayModel? {
        switch self {
        case let .scanningResult(model, _): return model
        default: return nil
        }
    }
    
    var activitySpinnerVisible: Bool {
        switch self {
        case .scanningResult, .scanningNoResult: return true
        default: return false
        }
    }
    
    var resultViewVisible: Bool {
        switch self {
        case .scanningResult: return true
        default: return false
        }
    }
    
    var standBackHintVisible: Bool {
        switch self {
        case .scanningNoResult: return true
            
        case let .scanningResult(model, _):
            if model.confidence < 0.8 {
                return true
            }
            return false
            
        default: return false
        }
    }
    
    var holdStillHintVisible: Bool {
        switch self {
        case .phoneMoving: return true
        default: return false
        }
    }
}

//
//  ShaderPaintViewModel.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

extension ShaderPaintViewController {
    struct ViewModel {
        var occlusionViewModel: OcclusionStateInfo
        
        func userHint(color: UIColor, font: UIFont, icon: UIImage?) -> NSAttributedString {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            
            let fullString = NSMutableAttributedString(
                string: "To get started, pick a color then tap on the ",
                attributes: attributes
            )
            
            let image1Attachment = NSTextAttachment()
            image1Attachment.bounds = CGRect(x: 0, y: 0, width: 21, height: 21)
            image1Attachment.image = icon?.withTintColor(color, renderingMode: .alwaysTemplate)
            
            let image1String = NSAttributedString(attachment: image1Attachment)
            
            fullString.append(image1String)
            fullString.append(NSAttributedString(string: " button above.",
                                                 attributes: attributes))
            
            return fullString
        }
        
        init() {
            occlusionViewModel = OcclusionStateInfoImpl()
        }
    }
}

extension ShaderPaintStateMachine.State {
    var tutorialVisible: Bool {
        switch self {
        case .tutorial: return true
        default: return false
        }
    }
    
    var paintSuccess: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var uiControlsVisible: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var cartButtonVisible: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var colorPickerVisible: Bool {
        switch self {
        case .pickingColor, .fullUI: return true
        default: return false
        }
    }
    
    func userHint(
        color: UIColor? = nil,
        font: UIFont? = nil,
        icon: UIImage? = nil
    ) -> NSAttributedString? {
        let color = color ?? .white
        let font = font ?? FontTheme.font(family: .SFProText,
                                          weight: .Medium,
                                          size: 16)
        let defaultIcon = UIImage(named: "colorRange")?
            .withTintColor(color, renderingMode: .alwaysTemplate)
        let icon = icon ?? defaultIcon
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        switch self {
        case .pickingColor:
            return NSAttributedString(
                string: "To get started, pick a color",
                attributes: attributes
            )
            
        case .fullUI:
            let part1 = NSAttributedString(
                string: "Tap on the ",
                attributes: attributes
            )
            let image = NSAttributedString(image: icon)
            let part2 = NSAttributedString(
                string: " button to fine tune your paint",
                attributes: attributes
            )
            return part1
                .appending(string: image)
                .appending(string: part2)
            
        default: return nil
        }
    }
}

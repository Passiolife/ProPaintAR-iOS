//
//  String+Extension.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 25/07/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension String {
    static var empty: String {
        ""
    }
    
    func size(OfFont font: UIFont) -> CGSize {
        self.size(withAttributes: [NSAttributedString.Key.font: font])
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

//
//  EmbeddedViewCoordinator.swift
//  Coordinator-Barebones
//
//  Created by Davido Hyer on 5/4/22.
//

import Combine
import Foundation
import UIKit

class EmbeddedViewCoordinator: Coordinator<String?> {
    lazy var embeddedViewController: EmbeddedViewController = {
        let controller = EmbeddedViewController.instantiate()
        controller.delegate = self
        return controller
    }()
    
    override func toPresentable() -> UIViewController {
        embeddedViewController
    }
}

extension EmbeddedViewCoordinator: EmbeddedViewControllerDelegate {
    func closeView(_ result: String?, controller: EmbeddedViewController) {
        finish(result)
    }
}

//
//  NeedsDependency.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/26/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation

protocol NeedsDependency: AnyObject {
    var dependencies: AppDependency { get set }
}

extension NeedsDependency where Self: PresentableCoordinatorType {
    func updateChildCoordinatorDependencies() {
        self.childCoordinators.values.forEach { coordinator in
            if let coordinator = coordinator as? NeedsDependency {
                coordinator.dependencies = dependencies
            }
        }
    }
}

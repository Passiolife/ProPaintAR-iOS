//
//  WindowCoordinator.swift
//  Remodel-AR WL
//
//  Created by Ian MacCallum on 10/11/17.
//

import Foundation
import UIKit

public protocol WindowCoordinatorType: BaseCoordinatorType {
	var router: WindowRouterType { get }
}

open class WindowCoordinator<CoordinationResult>: NSObject, WindowCoordinatorType {
	public var childCoordinators: [PresentableCoordinator<CoordinationResult>] = []
    public var presenter: UIViewController?
    
	open var router: WindowRouterType
	
	public init(router: WindowRouterType) {
		self.router = router
		super.init()
	}
	
    open func start() {}
    open func finish(_ result: CoordinationResult) {}
    
	public func addChild(_ coordinator: Coordinator<CoordinationResult>) {
		childCoordinators.append(coordinator)
	}
	
	public func removeChild(_ coordinator: Coordinator<CoordinationResult>?) {
        if let coordinator = coordinator, let index = childCoordinators.firstIndex(of: coordinator) {
			childCoordinators.remove(at: index)
		}
	}
}

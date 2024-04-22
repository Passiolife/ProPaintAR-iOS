//
//  WindowRouter.swift
//  Remodel-AR WL
//
//  Created by Ian MacCallum on 10/11/17.
//

import UIKit

public protocol WindowRouterType: AnyObject {
	var window: UIWindow { get }
    
	init(window: UIWindow)
	func setRootModule(_ module: Presentable)
}

public final class WindowRouter: NSObject, WindowRouterType {
	public unowned let window: UIWindow
	
	public init(window: UIWindow) {
		self.window = window
		super.init()
	}
	
	public func setRootModule(_ module: Presentable) {
		let viewController = module.toPresentable()
		window.rootViewController = viewController
	}
}

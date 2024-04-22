//
//  StoryboardLoadable.swift
//  Radiant Tap Essentials
//	https://github.com/radianttap/swift-essentials
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import UIKit

public protocol StoryboardLoadable {
	static var storyboardName: String { get }
	static var storyboardIdentifier: String { get }
}

extension StoryboardLoadable where Self: UIViewController {
	public static var storyboardName: String {
		String(describing: self)
	}

	public static var storyboardIdentifier: String {
		String(describing: self)
	}

    public static func instantiate(fromStoryboardNamed name: String) -> Self {
		let storyboard = UIStoryboard(name: name, bundle: nil)
		return instantiate(fromStoryboard: storyboard)
	}

	public static func instantiate(fromStoryboard storyboard: UIStoryboard) -> Self {
		let identifier = self.storyboardIdentifier
		guard let vc = storyboard.instantiateViewController(withIdentifier: identifier) as? Self else {
			fatalError("Failed to instantiate view controller with identifier=\(identifier) from storyboard \( storyboard )")
		}
		return vc
	}
	
    public static func initial(fromStoryboardNamed name: String) -> Self {
		let storyboard = UIStoryboard(name: name, bundle: nil)
		return initial(fromStoryboard: storyboard)
	}

	public static func initial(fromStoryboard storyboard: UIStoryboard) -> Self {
		guard let vc = storyboard.instantiateInitialViewController() as? Self else {
			fatalError("Failed to instantiate initial view controller from storyboard named \( storyboard )")
		}
		return vc
	}
}

extension UIViewController: StoryboardLoadable {}

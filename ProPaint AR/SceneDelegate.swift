//
//  SceneDelegate.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/28/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Bugsnag
import Mixpanel
import PassioRemodelAISDK
import RemodelAR
import SceneKit
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    lazy var appCoordinator: AppCoordinator = {
        let navigationController = UINavigationController()
        let router = RouterImpl(navigationController: navigationController)
        let dependencies = AppDependency.createDependencies()
        return AppCoordinator(router: router, dependencies: dependencies)
    }()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Replace license_key with your license key. If you need a key, you can request one by contacting support@passiolife.com
        let key = "license_key"
        let passioConfig = PassioConfiguration(key: key)
        PassioRemodelAI.shared.configure(passioConfiguration: passioConfig) { status in
            print("Mode = \(status.mode)\nmissingfiles = \(String(describing: status.missingFiles))")
        }
        PassioConfiguration.configure(license: key, releaseMode: .development)
        Mixpanel.initialize(token: "79c6e4fcc45081fb390bdfce1c2f7d86", trackAutomaticEvents: false)
        Bugsnag.start()

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = appCoordinator.toPresentable()
        window.makeKeyAndVisible()
        
        appCoordinator.start()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
      for context in URLContexts {
          if let host = context.url.host,
             host == "changestore",
             context.url.path.count == 7 {
              let storeId = context.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
              appCoordinator.loadStore(storeId: storeId)
          }
      }
    }
}

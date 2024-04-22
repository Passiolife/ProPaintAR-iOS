//
//  AppCoordinator.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/28/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

class AppCoordinator: Coordinator<Void> {
    lazy var homeCoordinator: HomeCoordinator = {
        let coordinator = HomeCoordinator(router: router, dependencies: dependencies)
        coordinator.delegate = self
        return coordinator
    }()

    lazy var storeCoordinator: StoreCoordinator = {
        let coordinator = StoreCoordinator(router: router,
                                           dependencies: dependencies)
        coordinator.delegate = self
        return coordinator
    }()

    override init(router: Router, dependencies: AppDependency, presenter: UIViewController? = nil) {
        super.init(router: router, dependencies: dependencies)
        self.presenter = presenter
    }

    override func start() {
        dependencies = AppDependency.createDependencies()

//        if dependencies.storeId == nil {
//            storeCoordinator.start()
//        } else {
            homeCoordinator.start()
//        }
    }
    
    func loadStore(storeId: String) {
        showStore(storeId: storeId)
    }
}

extension AppCoordinator: HomeCoordinatorDelegate {
    func showChangeStore() {
        StoreRepo.removeStoreID { [weak self] in
            guard let self = self else { return }
            
            self.addChild(self.storeCoordinator)
            self.storeCoordinator.start()
        }
    }
}

extension AppCoordinator: StoreCoordinatorDelegate {
    func showDemo() {
        dependencies = AppDependency.createDependencies()
        homeCoordinator.dependencies = dependencies
        addChild(homeCoordinator)
        homeCoordinator.start()
    }
    
    func showStore(storeId: String) {
        showChangeStore()
        DispatchQueue.main.async { [weak self] in
            self?.storeCoordinator.showLoadingIndicator(storeId: storeId)
        }
        StoreRepo.storeId = storeId
        dependencies = AppDependency.createDependencies(progress: { [weak self] progress in
            self?.storeCoordinator.updateProgress(progress: progress)
        }, done: { [weak self] in
            guard let self = self else { return }
            
            self.homeCoordinator.dependencies = self.dependencies
            self.addChild(self.homeCoordinator)
            self.homeCoordinator.start()
        })
    }
}

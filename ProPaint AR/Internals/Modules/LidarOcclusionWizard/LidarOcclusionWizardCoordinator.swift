//
//  LidarOcclusionWizardCoordinator.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 4/27/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

protocol LidarOcclusionWizardCoordinatorDelegate: AnyObject {
    func updateThreshold(threshold: Float)
    func toggleScanning(enabled: Bool)
    func resetLidarOcclusions()
}

class LidarOcclusionWizardCoordinator: Coordinator<Void> {
    weak var delegate: LidarOcclusionWizardCoordinatorDelegate?
    
    var threshold: Float
    private var cancellables = Set<AnyCancellable>()
    private lazy var localData = LidarOcclusionWizardViewController.LocalData(threshold: threshold)
    
    init(
        router: Router,
        dependencies: AppDependency,
        presenter: UIViewController? = nil,
        threshold: Float
    ) {
            self.threshold = threshold
            super.init(router: router, dependencies: dependencies, presenter: presenter)

            configureLocalData()
    }

    lazy var wizardViewController: LidarOcclusionWizardViewController = {
        let controller = LidarOcclusionWizardViewController.instantiate(fromStoryboardNamed: .ARMethods)
        controller.setDataModel(data: localData)
        controller.customizationRepo = dependencies.customizationRepo
        controller.delegate = self
        return controller
    }()
    
    override func toPresentable() -> UIViewController {
        wizardViewController
    }
    
    private func configureLocalData() {
        localData.$threshold
            .receive(on: RunLoop.main)
            .sink { [weak self] threshold in
                self?.delegate?.updateThreshold(threshold: threshold)
            }
            .store(in: &cancellables)
        
        localData.$isScanning
            .receive(on: RunLoop.main)
            .sink { [weak self] isScanning in
                self?.delegate?.toggleScanning(enabled: isScanning)
            }
            .store(in: &cancellables)
        
        localData.resetLidarOcclusions.sink { [weak self] _ in
            self?.delegate?.resetLidarOcclusions()
        }.store(in: &cancellables)
    }
}

extension LidarOcclusionWizardCoordinator: LidarOcclusionWizardViewControllerDelegate {
    func closeView(_ controller: LidarOcclusionWizardViewController) {
        finish(())
    }
}

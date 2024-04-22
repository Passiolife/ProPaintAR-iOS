//
//  LegacyCoordinator.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import RemodelAR
import UIKit

class LegacyCoordinator: Coordinator<Void> {
    private lazy var localData: LegacyViewController.LocalData = .init()
    private lazy var viewController: LegacyViewController = {
        let controller = LegacyViewController.instantiate(localData: localData)
        controller.delegate = self
        controller.customizationRepo = dependencies.customizationRepo
        return controller
    }()
    
    private var occlusionWizardCoordinator: OcclusionWizardCoordinator?
    private var lidarOcclusionWizardCoordinator: LidarOcclusionWizardCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    override func toPresentable() -> UIViewController {
        viewController
    }
    
    override func start() {
        super.start()
        
        configureData()
    }
    
    private func configureData() {
        dependencies.colorRepo.colorsPublisher.sink { [weak self] paints in
            self?.viewController.setPaints(paints: paints)
        }.store(in: &cancellables)
    }
}

extension LegacyCoordinator: LegacyViewControllerDelegate {
    func dismiss(_ controller: LegacyViewController) {
        router.popModule(animated: true)
    }
    
    func showOcclusionWizard(_ controller: LegacyViewController) {
        occlusionWizardCoordinator = OcclusionWizardCoordinator(
            router: router,
            dependencies: dependencies,
            presenter: controller,
            viewModel: localData.data.occlusionViewModel
        )
        
        occlusionWizardCoordinator?.delegate = self
        occlusionWizardCoordinator?.onFinish = { [weak self] _ in
            if let coordinator = self?.occlusionWizardCoordinator {
                controller.unembed(controller: coordinator)
            }
            self?.occlusionWizardCoordinator = nil
            self?.viewController.occlusionWizardStopped()
        }
        
        guard let occlusionWizardCoordinator = occlusionWizardCoordinator
        else { return }
        
        addChild(occlusionWizardCoordinator)
        occlusionWizardCoordinator.start()
        viewController.occlusionWizardStarted()
        
        controller.embed(controller: occlusionWizardCoordinator, into: nil)
    }
    
    func showLidarOcclusionWizard(_ controller: LegacyViewController) {
        lidarOcclusionWizardCoordinator = LidarOcclusionWizardCoordinator(
            router: router,
            dependencies: dependencies,
            presenter: controller,
            threshold: localData.data.lidarOcclusionThreshold
        )
        
        lidarOcclusionWizardCoordinator?.delegate = self
        lidarOcclusionWizardCoordinator?.onFinish = { [weak self] _ in
            if let coordinator = self?.lidarOcclusionWizardCoordinator {
                controller.unembed(controller: coordinator)
            }
            self?.lidarOcclusionWizardCoordinator = nil
            self?.viewController.occlusionWizardStopped()
        }
        
        guard let lidarOcclusionWizardCoordinator = lidarOcclusionWizardCoordinator
        else { return }
        
        addChild(lidarOcclusionWizardCoordinator)
        lidarOcclusionWizardCoordinator.start()
        viewController.occlusionWizardStarted()
        
        controller.embed(controller: lidarOcclusionWizardCoordinator, into: nil)
    }
    
    func showCart(paintInfo: PaintInfo, controller: LegacyViewController) {
        let coordinator = CartCoordinator(paintInfo: paintInfo,
                                          router: router,
                                          dependencies: dependencies,
                                          presenter: controller)

        coordinator.onFinish = { [weak self] _ in
            self?.router.popModule(animated: true)
        }
        
        addChild(coordinator)
        coordinator.start()

        router.push(coordinator, animated: true, completion: nil)
    }
    
    func retrievedWallColorSample(color: UIColor, controller: LegacyViewController) {
        occlusionWizardCoordinator?.selectedColor(color: color)
    }
    
    func resetTriggered() {
        localData.reset()
    }
}

extension LegacyCoordinator: OcclusionWizardCoordinatorDelegate {
    func updated(data: OcclusionStateInfo) {
        localData.updateOcclusionData(occlusionInfo: data)
    }
}

extension LegacyCoordinator: LidarOcclusionWizardCoordinatorDelegate {
    func updateThreshold(threshold: Float) {
        localData.setLidarOcclusionThreshold(threshold: threshold)
        viewController.setLidarOcclusionThreshold(threshold: threshold)
    }
    
    func toggleScanning(enabled: Bool) {
        viewController.toggleLidarOcclusionScan(enabled: enabled)
    }
    
    func resetLidarOcclusions() {
        viewController.resetLidarOcclusions()
    }
}

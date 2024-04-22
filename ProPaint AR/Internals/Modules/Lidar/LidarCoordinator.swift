//
//  LidarCoordinator.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import RemodelAR
import UIKit

class LidarCoordinator: Coordinator<Void> {
    private lazy var localData: LidarViewController.LocalData = .init()
    private lazy var viewController: LidarViewController = {
        let controller = LidarViewController.instantiate(localData: localData)
        controller.delegate = self
        controller.customizationRepo = dependencies.customizationRepo
        return controller
    }()
    
    private var occlusionWizardCoordinator: OcclusionWizardCoordinator?
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

extension LidarCoordinator: LidarViewControllerDelegate {
    func dismiss(_ controller: LidarViewController) {
        router.popModule(animated: true)
    }
    
    func showOcclusionWizard(_ controller: LidarViewController) {
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
    
    func showCart(paintInfo: PaintInfo, controller: LidarViewController) {
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
    
    func retrievedWallColorSample(color: UIColor, controller: LidarViewController) {
        occlusionWizardCoordinator?.selectedColor(color: color)
    }
    
    func resetTriggered() {
        localData.reset()
    }
}

extension LidarCoordinator: OcclusionWizardCoordinatorDelegate {
    func updated(data: OcclusionStateInfo) {
        localData.updateOcclusionData(occlusionInfo: data)
    }
}

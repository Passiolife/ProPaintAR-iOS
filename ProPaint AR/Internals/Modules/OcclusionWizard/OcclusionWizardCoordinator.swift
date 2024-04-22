//
//  OcclusionWizardCoordinator.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

protocol OcclusionWizardCoordinatorDelegate: AnyObject {
    func updated(data: OcclusionStateInfo)
}

class OcclusionWizardCoordinator: Coordinator<Void> {
    weak var delegate: OcclusionWizardCoordinatorDelegate?
    
    var viewModel: OcclusionStateInfo
    private var cancellables = Set<AnyCancellable>()
    private lazy var localData: OcclusionWizardViewController.LocalData = .init(data: viewModel)
    
    init(
        router: Router,
        dependencies: AppDependency,
        presenter: UIViewController? = nil,
        viewModel: OcclusionStateInfo
    ) {
            self.viewModel = viewModel
            super.init(router: router, dependencies: dependencies, presenter: presenter)

            configureLocalData()
    }

    lazy var wizardViewController: OcclusionWizardViewController = {
        let controller = OcclusionWizardViewController.instantiate(fromStoryboardNamed: .ARMethods)
        controller.setDataModel(data: localData)
        controller.customizationRepo = dependencies.customizationRepo
        controller.delegate = self
        return controller
    }()
    
    override func toPresentable() -> UIViewController {
        wizardViewController
    }
    
    private func configureLocalData() {
        localData.$data
            .receive(on: RunLoop.main)
            .sink { [weak self] viewModel in
                self?.wizardViewController.updateView()
                self?.delegate?.updated(data: viewModel)
            }
            .store(in: &cancellables)
    }
    
    func selectedColor(color: UIColor) {
        if localData.state == .pickingColors {
            wizardViewController.addColor(color: color)
        }
    }
}

extension OcclusionWizardCoordinator: OcclusionWizardViewControllerDelegate {
    func closeView(_ controller: OcclusionWizardViewController) {
        finish(())
    }
}

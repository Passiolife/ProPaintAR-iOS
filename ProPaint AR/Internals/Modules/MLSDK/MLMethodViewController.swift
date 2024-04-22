//
//  MLMethodViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/2/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import AVFoundation
import Combine
import CoreMotion
import MLCompute
import PassioRemodelAISDK
import RemodelAR
import SceneKit
import UIKit
import VideoToolbox
import Vision

protocol MLMethodViewControllerDelegate: AnyObject {
    func dismiss(_ controller: MLMethodViewController)
}

class MLMethodViewController: UIViewController, Trackable {
    weak var delegate: MLMethodViewControllerDelegate?
    
    @IBOutlet weak var activitySpinner: ActivitySpinnerButton?
    @IBOutlet weak var homeButton: ImageButton?
    @IBOutlet weak var cropBracket: UIImageView?
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var scanResultView: RoundedView?
    @IBOutlet weak var scanResultLabel: PaddedTextView?
    @IBOutlet weak var holdStillHintLabel: PaddedTextView?
    @IBOutlet weak var standBackHintLabel: PaddedTextView?
    @IBOutlet weak var cameraSegmentedControl: UISegmentedControl!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var debugContainer: UIView!
    @IBOutlet weak var debugTableView: UITableView!
    
    private let motionManager = CMMotionManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var mlManager: MLManager?
    private var stateMachine = MLStateMachine()
    private var disappearTimer: Timer?
    private var sensorTimer: Timer?
    private var rotationTrend: Float = 0
    private var cropType: CropType = .cropped
    private var showConfidence = false
    var customizationRepo: CustomizationRepo?
    
    private var activeModelType: ModelType = .environments {
        didSet {
            mlManager?.setModelType(modelType: activeModelType)
        }
    }
    
    private var debugLines = [String]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.debugTableView.reloadData()
            }
        }
    }
    
    private var isPhoneStill = true {
        didSet {
            mlManager?.setPhoneMotion(isPhoneStill: isPhoneStill)
            if !isPhoneStill {
                stateMachine.phoneMoving()
            } else {
                stateMachine.phoneStilled()
            }
        }
    }
    
    internal static func instantiate(
        model: ModelType,
        customizationRepo: CustomizationRepo?,
        delegate: MLMethodViewControllerDelegate
    ) -> Self {
        let vc = Self.instantiate(fromStoryboardNamed: .MLMethods)
        vc.activeModelType = model
        vc.customizationRepo = customizationRepo
        vc.delegate = delegate
        vc.configureStateMachine()
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGestures()
        setupMLManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        standBackHintLabel?.text = activeModelType.instructionText
        imageView?.roundCorners(radius: 10)
        super.viewWillAppear(animated)
        applyUICustomization()
        mlManager?.setupPreviewLayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGyros()
        mlManager?.teardown()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startGyros()
        
        trackScreenView(event: "started")
        trackScreenTime(event: "closed")
    }
    
    private func setupMLManager() {
        guard let cropBracket = cropBracket
        else { return }
        
        mlManager = MLManager(parentView: view, cropView: cropBracket)
        mlManager?.setModelType(modelType: activeModelType)
        mlManager?.setCropType(cropType: cropType)
        
        mlManager?.scanSuccess = { [weak self] result in
            self?.stateMachine.scanSuccess(result: result)
        }
        
        mlManager?.debugLinesUpdated = { [weak self] debugLines in
            self?.debugLines = debugLines
        }
    }
}

private typealias IBActions = MLMethodViewController
extension IBActions {
    @IBAction func homeTapped(_ sender: Any) {
        trackScreenView(event: "closed")
        delegate?.dismiss(self)
    }
    
    @IBAction func cameraModeChanged(_ sender: UISegmentedControl) {
        cropType = CropType(rawValue: sender.selectedSegmentIndex) ?? .full
        mlManager?.setCropType(cropType: cropType)
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleConfidence))
        tapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture)
        
        let alternatesTapGesture = UITapGestureRecognizer(target: self,
                                                          action: #selector(toggleDebugAlternates))
        alternatesTapGesture.numberOfTapsRequired = 2
        alternatesTapGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(alternatesTapGesture)
    }
    
    @objc
    private func toggleConfidence() {
        showConfidence.toggle()
    }
    
    @objc
    private func toggleDebugAlternates() {
        debugContainer.isHidden.toggle()
    }
}

private typealias Motion = MLMethodViewController
extension Motion {
    func startGyros() {
        if motionManager.isGyroAvailable {
            let updateFPS: Double = 30
            motionManager.gyroUpdateInterval = 1.0 / updateFPS
            motionManager.startGyroUpdates()
            
            // Configure a timer to fetch the accelerometer data.
            sensorTimer = Timer(fire: Date(), interval: (1.0 / updateFPS),
                                repeats: true, block: { [weak self] _ in
                guard let self = self else { return }
                
                if let gyroData = self.motionManager.gyroData {
                    let gyro = SCNVector3(x: Float(gyroData.rotationRate.x),
                                          y: Float(gyroData.rotationRate.y),
                                          z: Float(gyroData.rotationRate.z))
                    let magnitude = gyro.length()
                    self.rotationTrend = self.rotationTrend.rollingAverage(
                        value: magnitude,
                        averageCount: 15
                    )
                    self.isPhoneStill = self.rotationTrend < 0.2
                }
            })
            
            if let sensorTimer = sensorTimer {
                RunLoop.current.add(sensorTimer, forMode: .default)
            }
        }
    }
    
    func stopGyros() {
        sensorTimer?.invalidate()
        sensorTimer = nil
        motionManager.stopGyroUpdates()
    }
}

private typealias UIConfiguration = MLMethodViewController
extension UIConfiguration {
    private func configureView(object: MLDisplayModel?) {
        func showNoResult() {
            self.standBackHintLabel?.isHidden = false
            self.scanResultView?.isHidden = true
            self.holdStillHintLabel?.isHidden = true
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let object = object,
                  object.confidence >= 2
            else {
                showNoResult()
                return
            }
            
            if let image = UIImage(named: object.objectID) {
                self.imageView?.image = image
            } else {
                if let customizationRepo = self.customizationRepo {
                    let uiOptions = customizationRepo.options.uiOptions
                    let mlMethodIcons = uiOptions.buttonIcons.mlMethodIcons
                    
                    switch self.activeModelType {
                    case .abnormalities, .abnormalitiesSSD:
                        let abnormalityIcon = mlMethodIcons.abnormalityIcon
                        self.imageView?.setImage(with: abnormalityIcon,
                                                 placeholder: self.activeModelType.image)
                        
                    case .environments:
                        let environmentIcon = mlMethodIcons.environmentIcon
                        self.imageView?.setImage(with: environmentIcon,
                                                 placeholder: self.activeModelType.image)
                        
                    case .surfaces:
                        let surfaceIcon = mlMethodIcons.surfaceIcon
                        self.imageView?.setImage(with: surfaceIcon,
                                                 placeholder: self.activeModelType.image)
                    }
                } else {
                    self.imageView?.image = self.activeModelType.image
                }
            }
            
            let (topResult, alternateResults) = object.displayResults(showConfidence: self.showConfidence)
            let alternates = alternateResults.isEmpty ? "" : "\n\nalternates:\n\(alternateResults)"
            if topResult.isEmpty {
                showNoResult()
                return
            }
            self.scanResultLabel?.text = "\(topResult)\(alternates)"
            
            self.scanResultView?.isHidden = false
            self.standBackHintLabel?.isHidden = true
            self.holdStillHintLabel?.isHidden = true
            
            self.disappearTimer?.invalidate()
            self.disappearTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                    self.scanResultView?.alpha = 0
                } completion: { _ in
                    self.scanResultView?.isHidden = true
                    self.scanResultView?.alpha = 1
                    
                    self.holdStillHintLabel?.isHidden = false
                    self.holdStillHintLabel?.alpha = 0
                    UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                        self.holdStillHintLabel?.alpha = 1
                    }
                }
            })
        }
    }
    
    private func applyUICustomization() {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let frameBackgroundColor = uiOptions.colors.frameBackground.color
        let overlayBackgroundColor = uiOptions.colors.overlayBackground.color
        let home = uiOptions.buttonIcons.methodInfoBackButtonIcon
        
        homeButton?.imageView.setImage(with: home, placeholder: nil)
        homeButton?.backgroundColor = frameBackgroundColor
        scanResultLabel?.font = uiOptions.font.font(with: 16)
        scanResultLabel?.textColor = textColor
        holdStillHintLabel?.font = uiOptions.font.font(with: 16)
        holdStillHintLabel?.textColor = textColor
        standBackHintLabel?.font = uiOptions.font.font(with: 16)
        standBackHintLabel?.textColor = textColor
        
        let activityFont = uiOptions.font.font(with: 16)
        activitySpinner?.setFont(font: activityFont)
        activitySpinner?.buttonTitleColor = buttonTextColor
        activitySpinner?.buttonFillColor = overlayBackgroundColor
        
        scanResultView?.backgroundColor = frameBackgroundColor
        
        let cameraFont = uiOptions.font.font(with: 14)
        let attr = [NSAttributedString.Key.font: cameraFont]
        
        cameraSegmentedControl.setTitleTextAttributes(attr, for: .normal)
    }
    
    private func updateView(viewModel: MLStateMachine.State) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if viewModel.holdStillHintVisible {
                self.holdStillHintLabel?.isHidden = false
                self.standBackHintLabel?.isHidden = true
                self.activitySpinner?.isHidden = true
                self.cropBracket?.isHidden = true
                self.scanResultView?.isHidden = true
            } else {
                let isCropMode = self.cropType != .full
                self.cropBracket?.isHidden = !(viewModel.activitySpinnerVisible && isCropMode)
                self.activitySpinner?.isHidden = !viewModel.activitySpinnerVisible
                self.configureView(object: viewModel.currentResult)
            }
        }
    }
}

private typealias AnalyticsTracking = MLMethodViewController
extension AnalyticsTracking {
    private func trackScreenView(event: String) {
        switch activeModelType {
        case .abnormalities:
            trackScreen(name: "mlsdk abnormalities \(event)")
            
        case .abnormalitiesSSD:
            trackScreen(name: "mlsdk abnormalities ssd \(event)")
            
        case .environments:
            trackScreen(name: "mlsdk environments \(event)")
            
        case .surfaces:
            trackScreen(name: "mlsdk surfaces \(event)")
        }
    }
    
    private func trackScreenTime(event: String) {
        switch activeModelType {
        case .abnormalities:
            trackTime(event: "mlsdk abnormalities \(event)")
            
        case .abnormalitiesSSD:
            trackTime(event: "mlsdk abnormalities ssd \(event)")
            
        case .environments:
            trackTime(event: "mlsdk environments \(event)")
            
        case .surfaces:
            trackTime(event: "mlsdk surfaces \(event)")
        }
    }
}

private typealias StateMachine = MLMethodViewController
extension StateMachine {
    private func configureStateMachine() {
        stateMachine.$statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] viewModel in
                guard let self = self
                else { return }
                
                self.updateView(viewModel: viewModel)
            }
            .store(in: &cancellables)
    }
}

extension MLMethodViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        debugLines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")

        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }

        cell?.textLabel?.text = debugLines[indexPath.row]
        
        return cell! // swiftlint:disable:this force_unwrapping
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        35
    }
}

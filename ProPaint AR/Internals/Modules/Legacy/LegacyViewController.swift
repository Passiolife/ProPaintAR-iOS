//
//  LegacyViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import ARKit
import Bugsnag
import Combine
import Foundation
import Kingfisher
import PromiseKit
import RemodelAR
import UIKit

protocol LegacyViewControllerDelegate: AnyObject {
    func dismiss(_ controller: LegacyViewController)
    func showOcclusionWizard(_ controller: LegacyViewController)
    func showLidarOcclusionWizard(_ controller: LegacyViewController)
    func showCart(paintInfo: PaintInfo, controller: LegacyViewController)
    func retrievedWallColorSample(color: UIColor, controller: LegacyViewController)
    func resetTriggered()
}

class LegacyViewController: UIViewController, Trackable {
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var tutorialTitle: UILabel!
    @IBOutlet weak var tutorialContent: UILabel!
    @IBOutlet weak var tutorialOkButton: UIButton!
    
    @IBOutlet weak var uiControls: UIStackView!
    @IBOutlet weak var cartButton: ImageButton!
    @IBOutlet weak var homeButton: ImageButton!
    @IBOutlet weak var userInstructions: PaddedTextView!
    @IBOutlet weak var colorPicker: PaintPickerView?
    @IBOutlet weak var userHint: PaddedTextView!
    @IBOutlet weak var userHintSecondary: PaddedTextView!
    @IBOutlet weak var scanOverlay: UIView!
    @IBOutlet weak var scanOverlayText: UITextView!
    @IBOutlet weak var placeWallButton: RoundedButton!
    @IBOutlet weak var placingWallView: UIView!
    @IBOutlet weak var placingWallActivityLabel: UILabel!
    @IBOutlet weak var placingWallActivitySpinner: ProgressCircle!
    @IBOutlet weak var donePickingColorButton: RoundedButton!
    @IBOutlet weak var occlusionsButton: ImageButton!
    @IBOutlet weak var saveImageButton: ImageButton!
    @IBOutlet private weak var sceneResetButton: ImageButton!
    @IBOutlet weak var deselectWallsButton: ImageButton!
    @IBOutlet weak var addWallButton: ImageButton!
    @IBOutlet weak var deleteWallButton: ImageButton!
    @IBOutlet weak var lidarOcclusionScanButton: ImageButton!
    
    weak var delegate: LegacyViewControllerDelegate?
    private var arController: ARController?
    private var cancellables = Set<AnyCancellable>()
    private var arscnView: ARSCNView?
    private var lastOcclusionUpdate = Date()
    private var occlusionUpdateTimer: Timer?
    private var localData: LocalData! // swiftlint:disable:this implicitly_unwrapped_optional
    private var stateMachine = LegacyStateMachine()
    private var wallDistance: Float?
    private var wallAngle: Float?
    private var currentSelectedWallId: UUID?
    private var lastState: LegacyStateMachine.State = .colorPicked
    private var isShowingCart = false
    
    var customizationRepo: CustomizationRepo?

    private var uiControlsVisible = false {
        didSet {
            updateDeselectButton()
        }
    }
    private var isWallSelected = false {
        didSet {
            updateDeselectButton()
        }
    }
    
    private var currentPaint: Paint? {
        didSet {
            guard let paint = currentPaint
            else { return }
            
            arController?.setColor(paint: paint.wallPaint, texture: paint.texture)
        }
    }
    
    private var paints: [Paint] = [] {
        didSet {
            colorPicker?.reloadPicker()
        }
    }
    
    internal static func instantiate(localData: LocalData) -> Self {
        let vc = Self.instantiate(fromStoryboardNamed: .ARMethods)
        vc.localData = localData
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureObservers()
        configureLocalData()
        configureStateMachine()
        configurePaintPicker()
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: Started")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isMovingToParent {
            trackTime(event: "Swatch closed")
            trackTime(event: "Swatch paint success")
            trackScreen(name: "Swatch", parameters: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureView()
        configureAR()
        applyUICustomization()
        updateView(viewModel: stateMachine.statePublisher)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            trackEvent(name: "legacy closed", parameters: nil)
        }
        tearDown()
    }
    
    func occlusionWizardStarted() {
        arController?.setPaintTouchMode(mode: .wizard)
        arController?.enableBrightnessTapAdjustment(enabled: false)
    }
    
    func occlusionWizardStopped() {
        arController?.setPaintTouchMode(mode: .normal)
        arController?.enableBrightnessTapAdjustment(enabled: true)
        stateMachine.hideOcclusionWizard()
        stateMachine.hideLidarOcclusionWizard()
    }
    
    func toggleLidarOcclusionScan(enabled: Bool) {
        if enabled {
            arController?.startLidarOcclusionScan()
        } else {
            arController?.stopLidarOcclusionScan()
        }
    }
    
    func setLidarOcclusionThreshold(threshold: Float) {
        arController?.setOcclusionDepthThreshold(threshold: threshold)
    }
    
    func resetLidarOcclusions() {
        arController?.resetLidarOcclusions()
    }
    
    private func updateDeselectButton() {
        let uiControlsVisible = stateMachine.statePublisher.uiControlsVisible
        let isHidden = !(uiControlsVisible && isWallSelected)
        self.deselectWallsButton.isHidden = isHidden
    }
}

private typealias StateMachine = LegacyViewController
extension StateMachine {
    private func configureStateMachine() {
        stateMachine.selectedSecondaryColor = { [weak self] color in
            self?.currentPaint = color
        }
                
        stateMachine.sceneReset = { [weak self] in
            self?.userHint.clearQueue()
            self?.delegate?.resetTriggered()
            self?.arController?.resetScene(startMode: .scanning)
            let paint = WallPaint(id: "",
                                  name: "",
                                  color: .clear,
                                  userColor: false)
            self?.arController?.setColor(paint: paint,
                                         texture: nil)
            self?.currentPaint = nil
            self?.colorPicker?.hideSecondaryPaintPicker()
            self?.colorPicker?.scrollToPaint(for: .primary,
                                             at: IndexPath(row: 0,
                                                           section: 0))
        }
        
        stateMachine.placeWallCommand = { [weak self] in
            self?.trackEvent(name: "legacy placed plane", parameters: nil)
            self?.arController?.placeBasePlane()
        }
        
        stateMachine.deleteWallCommand = { [weak self] in
            self?.trackEvent(name: "legacy deleted plane", parameters: nil)
            self?.showMessage(title: "Delete Wall",
                              message: "Are you sure you want to delete the selected wall?",
                              cancelTitle: "cancel",
                              okTitle: "delete",
                              okAction: { _ in
                self?.arController?.deleteWall(id: self?.currentSelectedWallId)
            })
        }
        
        stateMachine.showOcclusionWizardAction = { [weak self] in
            guard let self = self else { return }
            
            delegate?.showOcclusionWizard(self)
        }
        
        stateMachine.showLidarOcclusionWizardAction = { [weak self] in
            guard let self = self else { return }
            
            delegate?.showLidarOcclusionWizard(self)
        }
    }
}

private typealias IBActions = LegacyViewController
extension IBActions {
    @IBAction func hideTutorialAction(_ sender: Any) {
        stateMachine.tutorialFinished()
    }
    
    @IBAction func homeTapped(_ sender: Any) {
        delegate?.dismiss(self)
    }
    
    @IBAction func saveImageTapped(_ sender: Any) {
        arController?.hideOutlineState()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            guard let self = self,
                  let photo = self.arController?.savePhoto()
            else { return }
            
            self.arController?.restoreOutlineState()
            
            Bugsnag.leaveBreadcrumb(withMessage: "Legacy: save photo")
            self.trackEvent(name: "saved photo", parameters: nil)
            UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
            self.userHint.enqueueMessage(message: "Photo saved to album",
                                         duration: 2)
        }
    }
    
    @IBAction func resetTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: reset")
        trackEvent(name: "reset scene", parameters: nil)
        stateMachine.reset()
    }
    
    @IBAction func occlusionWizardTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: show occlusion wizard")
        stateMachine.showOcclusionWizard()
    }
    
    @IBAction func lidarOcclusionWizardTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: show lidar occlusion wizard")
        stateMachine.showLidarOcclusionWizard()
    }
    
    @IBAction func cartTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: show cart")
        trackEvent(name: "show cart", parameters: nil)
        isShowingCart = true
        arController?.retrievePaintInfo()
        arController?.pauseScene()
    }
    
    @IBAction func placeWallAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: place wall")
        stateMachine.placeWall()
    }
    
    @IBAction func donePickingColorAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: done picking color")
        stateMachine.donePickingColor()
    }
    
    @IBAction func deselectWallsAction(_ sender: Any) {
        arController?.deselectMeshes()
        isWallSelected = false
    }
    
    @IBAction func addWallAction(_ sender: Any) {
        stateMachine.addNewWall()
    }
    
    @IBAction func deleteWallAction(_ sender: Any) {
        stateMachine.deleteWall()
    }
}

private typealias Configuration = LegacyViewController
extension Configuration {
    public func setPaints(paints: [Paint]) {
        self.paints = paints
    }
    
    private func configureAR() {
    }
    
    private func configureLocalData() {
        localData.$data
            .receive(on: RunLoop.main)
            .sink { [weak self] viewModel in
                self?.updateOcclusionInfo(occlusionInfo: viewModel.occlusionViewModel)
            }
            .store(in: &cancellables)
        
        stateMachine.$statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] viewModel in
                guard let self = self
                else { return }
                
                self.updateView(viewModel: viewModel)
                
                if self.stateMachine.statePublisher != self.lastState {
                    switch self.stateMachine.statePublisher {
                    case .tutorial:
                        self.trackScreen(name: "Swatch tutorial", parameters: nil)
                        
                    case .scanning:
                        self.trackScreen(name: "Swatch scanning", parameters: nil)
                        
                    case .pickingColor:
                        self.trackScreen(name: "Swatch picking color", parameters: nil)
                        
                    case .colorPicked:
                        self.trackScreen(name: "Swatch color picked", parameters: nil)
                        
                    case .readyToPlaceWall:
                        self.trackScreen(name: "Swatch ready to place wall", parameters: nil)
                        
                    case .placingWall:
                        self.trackScreen(name: "Swatch placing wall", parameters: nil)
                        
                    case .placingFirstCorner:
                        self.trackScreen(name: "Swatch placing first corner", parameters: nil)
                        
                    case .placingSecondCorner:
                        self.trackScreen(name: "Swatch placing second corner", parameters: nil)
                        
                    case .fullUI:
                        self.trackEvent(name: "legacy paint success", parameters: nil)
                        
                    default: break
                    }
                }
                self.lastState = self.stateMachine.statePublisher
            }
            .store(in: &cancellables)
    }
    
    private func updateView(viewModel: LegacyStateMachine.State) {
        if viewModel.isWizardVisible {
            hideAllUI()
        } else {
            lidarOcclusionScanButton.isHidden = !viewModel.uiControlsVisible
            tutorialView.isHidden = !viewModel.tutorialVisible
            addWallButton.isHidden = !viewModel.addButtonVisible
            uiControlsVisible = viewModel.uiControlsVisible
            uiControls.isHidden = !viewModel.uiControlsVisible
            cartButton.isHidden = !viewModel.cartButtonVisible
            colorPicker?.isHidden = !viewModel.colorPickerVisible
            scanOverlay.isHidden = !viewModel.scanOverlayVisible
            placeWallButton.isHidden = !viewModel.placeWallButtonVisible
            userInstructions.isHidden = !viewModel.userInstructionsVisible
            userInstructions.text = viewModel.userInstructions
            userHint.isHidden = !viewModel.userHintVisible
            userHintSecondary.isHidden = !viewModel.secondaryHintVisible
            let doneVisible = viewModel.donePickingColorButtonVisible && currentPaint != nil
            donePickingColorButton.isHidden = !doneVisible
            placingWallView.isHidden = !viewModel.placingWallViewVisible
            placingWallActivityLabel.text = viewModel.placingWallActivityMessage
            placingWallActivitySpinner.isHidden = !viewModel.placingWallActivityVisible
            placingWallActivitySpinner.update(progress: viewModel.placingWallProgress, animated: false)
            deleteWallButton.isHidden = !(currentSelectedWallId != nil && viewModel.uiControlsVisible)
            updateDeselectButton()
            
            if let userHintMessages = viewModel.userHint {
                userHint.enqueueMessages(messages: userHintMessages)
            }
        }
    }
    
    private func hideAllUI() {
        lidarOcclusionScanButton.isHidden = true
        tutorialView.isHidden = true
        addWallButton.isHidden = true
        uiControlsVisible = true
        uiControls.isHidden = true
        cartButton.isHidden = true
        colorPicker?.isHidden = true
        scanOverlay.isHidden = true
        placeWallButton.isHidden = true
        userInstructions.isHidden = true
        userHint.isHidden = true
        userHintSecondary.isHidden = true
        donePickingColorButton.isHidden = true
        placingWallView.isHidden = true
        placingWallActivitySpinner.isHidden = true
        deleteWallButton.isHidden = true
        deselectWallsButton.isHidden = true
    }
    
    private func updateOcclusionInfo(occlusionInfo: OcclusionStateInfo) {
        occlusionUpdateTimer?.invalidate()
        if Date().timeIntervalSince(lastOcclusionUpdate) < 0.05 {
            occlusionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05,
                                                        repeats: false,
                                                        block: { [weak self] _ in
                guard let self = self else { return }
                self.arController?.setOcclusionColors(
                    colors: self.localData.data.occlusionViewModel.colors
                )
                self.arController?.setColorThreshold(
                    threshold: self.localData.data.occlusionViewModel.threshold
                )
                self.lastOcclusionUpdate = Date()
            })
        } else {
            arController?.setOcclusionColors(colors: occlusionInfo.colors)
            arController?.setColorThreshold(threshold: occlusionInfo.threshold)
            lastOcclusionUpdate = Date()
        }
    }
    
    private func configureView() {
        createARView()
        configureBindings()
        arController?.startScene(reset: true)
        placeWallButton.fixTextAlignment()
        donePickingColorButton.fixTextAlignment()
    }
    
    private func tearDown() {
        occlusionUpdateTimer?.invalidate()
        arController?.tearDown()
    }
    
    private func configureObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appMovedToBackground() {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: App backgrounded")
        trackEvent(name: "app moved to background", parameters: nil)
        arController?.pauseScene()
    }

    @objc private func appMovedToForeground() {
        Bugsnag.leaveBreadcrumb(withMessage: "Legacy: App foregrounded")
        trackEvent(name: "app moved to foreground", parameters: nil)
        arController?.startScene(reset: false)
    }
    
    private func createARView() {
        addAndConfigureARViews()
        addGestureOnARView()
    }
    
    private func addAndConfigureARViews() {
        arscnView = ARSCNView()
        guard let arscnView = arscnView
        else { return }
        
        view.addSubview(arscnView)
        view.sendSubviewToBack(arscnView)
        arscnView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            arscnView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            arscnView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            arscnView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            arscnView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

        arController = RemodelARLib.makeSwatchARController(with: arscnView)
    }
    
    private func configureBindings() {
        arController?.wallPainted = { [weak self] in
            var parameters: [String: Any]?
            if let currentPaint = self?.currentPaint {
                self?.stateMachine.selectSecondaryColor(color: currentPaint)
                parameters = ["color": currentPaint.color.toHexString()]
            }
            self?.trackEvent(name: "legacy wall painted", parameters: parameters)
            self?.stateMachine.paintFirstWall()
        }
        arController?.trackingReady = { [weak self] isReady in
            guard isReady else { return }
            
            self?.stateMachine.scanFinished()
            
            DispatchQueue.main.async {
                self?.colorPicker?.reloadPicker()
            }
        }
        arController?.retrievedWallColorSample = { [weak self] color in
            guard let self = self else { return }

            self.delegate?.retrievedWallColorSample(color: color, controller: self)
        }
        arController?.cameraAimInfoUpdated = { [weak self] aimInfo in
            guard let self = self,
                  let aimInfo = aimInfo
            else { return }
            
            self.stateMachine.deviceAngleUpdated(angle: aimInfo.angle)
            self.stateMachine.wallAimInfoUpdated(distance: aimInfo.wallDistance,
                                                 angle: aimInfo.wallOrientation)
        }
        arController?.placeWallStateUpdated = { [weak self] placeWallState in
            switch placeWallState {
            case .placingSecondCorner:
                self?.stateMachine.firstCornerSet()
                
            case .done:
                self?.stateMachine.secondCornerSet()
                self?.isWallSelected = true
                
            default: return
            }
        }
//        arController?.analyticsTracking = { event in
//            print("event: \(event.analyticsData.event)")
//        }
        arController?.isWallSelected = { [weak self] isWallSelected in
            self?.isWallSelected = isWallSelected
        }
        
        arController?.currentSelectedWallId = { [weak self] id in
            self?.currentSelectedWallId = id
        }
        
        arController?.retrievedPaintInfo = { [weak self] paintInfo in
            guard let self = self,
                  self.isShowingCart
            else { return }
            
            self.delegate?.showCart(paintInfo: paintInfo, controller: self)
        }
    }
    
    private func customizeARImages(repo: CustomizationRepo) {
        let arOptions = repo.options.arOptions
        let legacy = repo.options.arOptions.legacy
        if let lowerLeftResource = legacy.cornerImages.lowerLeft.0?.resource,
           let lowerRightResource = legacy.cornerImages.lowerRight.0?.resource,
           let upperLeftResource = legacy.cornerImages.upperLeft.0?.resource,
           let upperRightResource = legacy.cornerImages.upperRight.0?.resource,
           let centerDotResource = legacy.centerDot.0?.resource,
           let centerDotOuterResource = legacy.centerDotOuter.0?.resource {
            var lowerLeftImage, lowerRightImage, upperLeftImage, upperRightImage: UIImage?
            var centerDotImage, centerDotOuterImage: UIImage?

            firstly {
                centerDotResource.downloadImage()
            }.then { centerDot -> Promise<UIImage?> in
                centerDotImage = centerDot
                return centerDotOuterResource.downloadImage()
            }.then { centerDotOuter -> Promise<UIImage?> in
                centerDotOuterImage = centerDotOuter
                return lowerLeftResource.downloadImage()
            }.then { lowerLeft -> Promise<UIImage?> in
                lowerLeftImage = lowerLeft
                return lowerRightResource.downloadImage()
            }.then { lowerRight -> Promise<UIImage?> in
                lowerRightImage = lowerRight
                return upperLeftResource.downloadImage()
            }.then { upperLeft -> Promise<UIImage?> in
                upperLeftImage = upperLeft
                return upperRightResource.downloadImage()
            }.done { upperRight in
                upperRightImage = upperRight
                
                var legacyImages = [Corners: UIImage]()
                if let lowerLeftImage = lowerLeftImage,
                   let lowerRightImage = lowerRightImage,
                   let upperLeftImage = upperLeftImage,
                   let upperRightImage = upperRightImage {
                    legacyImages = [.lowerLeftCorner: lowerLeftImage,
                                    .lowerRightCorner: lowerRightImage,
                                    .upperLeftCorner: upperLeftImage,
                                    .upperRightCorner: upperRightImage]
                }
                
                self.arController?.setSwatchUIImages(
                    cornerTextures: legacyImages,
                    centerDot: centerDotImage,
                    centerDotOuter: centerDotOuterImage
                )
            }.catch { error in
                print("Error downloading custom images: \(error.localizedDescription)")
            }
        }
        
        if let gridResource = arOptions.gridImage.0?.resource {
            gridResource.downloadImage { [weak self] image in
                if let image = image {
                    self?.arController?.setGridImage(gridImage: image)
                }
            }
        }
    }
    
    private func applyUICustomization() {
        if let customizationRepo = customizationRepo {
            customizeARImages(repo: customizationRepo)
            
            let arOptions = customizationRepo.options.arOptions
            let uiOptions = customizationRepo.options.uiOptions
            let textColor = uiOptions.colors.text.color
            let buttonTextColor = uiOptions.colors.buttonText.color
            let resetIcon = uiOptions.buttonIcons.resetSceneIcon
            let saveImageIcon = uiOptions.buttonIcons.saveImageIcon
            let occlusionsIcon = uiOptions.buttonIcons.shaderOcclusionsIcon
            let homeIcon = uiOptions.buttonIcons.homeIcon
            let cartIcon = uiOptions.buttonIcons.shoppingCartIcon
            let hideWallsIcon = uiOptions.buttonIcons.hideFloorplanUnpaintedIcon
            
            sceneResetButton.imageView.setImage(with: resetIcon, placeholder: nil)
            occlusionsButton.imageView.setImage(with: occlusionsIcon, placeholder: nil)
            saveImageButton.imageView.setImage(with: saveImageIcon, placeholder: nil)
            homeButton.imageView.setImage(with: homeIcon, placeholder: nil)
            cartButton.imageView.setImage(with: cartIcon, placeholder: nil)
            deselectWallsButton.imageView.setImage(with: hideWallsIcon, placeholder: nil)
            
            let doneFont = uiOptions.font.font(with: 16)
            donePickingColorButton.titleLabel?.font = doneFont
            donePickingColorButton.setTitleColor(buttonTextColor, for: .normal)
            
            let placeFont = uiOptions.font.font(with: 16)
            placeWallButton.titleLabel?.font = placeFont
            placeWallButton.setTitleColor(buttonTextColor, for: .normal)
            
            let placingWallFont = uiOptions.font.font(with: 16)
            placingWallActivityLabel.font = placingWallFont
            placingWallActivityLabel.textColor = textColor
            placingWallActivityLabel.setLineHeight(lineHeight: 1.3)
            
            let scanFont = uiOptions.font.font(with: 16)
            scanOverlayText.font = scanFont
            scanOverlayText.textColor = textColor
            
            let userInstructionFont = uiOptions.font.font(with: 16)
            userInstructions.setFont(font: userInstructionFont)
            userInstructions.textColor = textColor
            
            let userHintFont = uiOptions.font.font(with: 16)
            userHint.setFont(font: userHintFont)
            userHint.textColor = textColor
            
            let userHint2Font = uiOptions.font.font(with: 16)
            userHintSecondary.setFont(font: userHint2Font)
            userHintSecondary.textColor = textColor
            
            let primaryFont = uiOptions.font.font(with: 16)
            let secondaryFont = uiOptions.font.font(with: 16)
            colorPicker?.configurePrimaryTitleLabelStyle(primaryFont, textColor)
            colorPicker?.configureSecondaryTitleLabelStyle(secondaryFont, textColor)
            
            let scanStyleRaw = arOptions.lidar.scanStyle.rawInt
            if let scanStyle = LidarScanStyle(rawValue: scanStyleRaw) {
                arController?.setLidarScanStyle(scanStyle: scanStyle)
            }
            
            let tutorialTitleFont = uiOptions.font.font(with: 18)
            let tutorialBodyFont = uiOptions.font.font(with: 14)
            tutorialTitle.font = tutorialTitleFont
            tutorialContent.font = tutorialBodyFont
            tutorialOkButton.titleLabel?.font = uiOptions.font.font(with: 14)
            tutorialTitle.textColor = textColor
            tutorialContent.textColor = textColor
            tutorialOkButton.setTitleColor(textColor, for: .normal)
        } else {
            let centerDotOuter = UIImage(named: "centerDotOuter")
            arController?.setSwatchUIImages(cornerTextures: [:],
                                            centerDot: nil,
                                            centerDotOuter: centerDotOuter)
            let frontConfig = TargetParameters(scale: 0.25)
            let backConfig = TargetParameters(scale: 0.25,
                                              animationScale: 1,
                                              loopDuration: 0.35,
                                              opacity: 1,
                                              isAnimated: true)
            let config = TargetConfig(frontParameters: frontConfig, backParameters: backConfig)
            arController?.animateTarget(config: config)
        }
    }
}

private typealias Gestures = LegacyViewController
extension Gestures {
    private func addGestureOnARView() {
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(onDraggingARView(_:)))
        arscnView?.isUserInteractionEnabled = true
        arscnView?.addGestureRecognizer(dragGesture)
    }
    
    @objc private func onDraggingARView(_ sender: UIPanGestureRecognizer) {
        guard let arscnView = arscnView
        else { return }
        
        switch sender.state {
        case .began:
            arController?.dragStart(point: sender.location(in: arscnView))
            
        case .changed:
            arController?.dragMove(point: sender.location(in: arscnView))
            
        case .ended:
            arController?.dragEnd(point: sender.location(in: arscnView))
            
        default:
            break
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first
        else { return }
        
        let point = touch.location(in: arscnView)
        arController?.handleTouch(point: point)
    }
}

private typealias PaintPickerData = LegacyViewController
extension PaintPickerData: PaintPickerDataSource {
    private func configurePaintPicker() {
        colorPicker?.dataSource = self
        colorPicker?.delegate = self
        colorPicker?.configurePrimaryTitleLabelStyle(
            FontTheme.font(family: .Montserrat,
                           weight: .Bold,
                           size: 22),
            .white
        )
        colorPicker?.configureSecondaryTitleLabelStyle(
            FontTheme.font(family: .Montserrat,
                           weight: .Regular ,
                           size: 19),
            .white)
    }
    
    func paints(for paintPicker: PaintPickerView) -> [Paint] {
        paints
    }

    func paintPickerView(_ paintPicker: PaintPickerView, cornerRadiusFor indexPath: IndexPath) -> CGFloat {
        10
    }
    
    func paintPickerView(_ paintPicker: PaintPickerView, shadowFor indexPath: IndexPath) -> PaintItemShadow? {
        PaintShadow(shadowColor: UIColor.black.cgColor,
                    shadowOpacity: 0.4,
                    shadowRadius: 4,
                    shadowOffset: .init(width: 0, height: 4))
    }
    
    func primaryPaintPickerView(
        _ paintPicker: PaintPickerView,
        borderWidthFor indexPath: IndexPath
    ) -> CGFloat {
        2.0
    }
    
    func secondaryPaintPickerView(
        _ paintPicker: PaintPickerView,
        borderWidthFor indexPath: IndexPath,
        primaryPaint index: Int
    ) -> CGFloat {
        2.0
    }
    
    func primaryPaintPickerView(
        _ paintPicker: PaintPickerView,
        borderColorFor indexPath: IndexPath
    ) -> CGColor {
        paints[indexPath.row].color.isLightColor ?
        UIColor.black.cgColor :
        UIColor.white.cgColor
    }
    
    func secondaryPaintPickerView(
        _ paintPicker: PaintPickerView,
        borderColorFor indexPath: IndexPath,
        primaryPaint index: Int
    ) -> CGColor {
        let color = paints[index].secondaryColors[indexPath.row]
        if color.color.isLightColor {
            return UIColor.black.cgColor
        } else {
            return UIColor.white.cgColor
        }
    }
    
    func primaryPaintPickerView(_ paintPicker: PaintPickerView, imageFor indexPath: IndexPath) -> UIImage? {
        guard paints.count > indexPath.row,
              let texture = paints[indexPath.row].texture
        else { return nil }
        
        return texture
    }
    
    func secondaryPaintPickerView(
        _ paintPicker: PaintPickerView,
        imageFor indexPath: IndexPath,
        primaryPaint index: Int
    ) -> UIImage? {
        guard paints.count > index,
              paints[index].secondaryColors.count > indexPath.row,
              let texture = paints[index].secondaryColors[indexPath.row].texture
        else { return nil }
        
        return texture
    }
}

private typealias PaintPickerDelegateCallbacks = LegacyViewController
extension PaintPickerDelegateCallbacks: PaintPickerDelegate {
    func paintPickerView(
        _ paintPicker: PaintPickerView,
        didSelectPaintAt indexPath: IndexPath,
        primary paint: Paint
    ) {
        guard let secondaryPaint = paint.secondaryColors.first
        else { return }
        
        stateMachine.selectPrimaryColor(color: paint)
        stateMachine.selectSecondaryColor(color: secondaryPaint)
    }
    
    func paintPickerView(
        _ paintPicker: PaintPickerView,
        didSelectPaintAt indexPath: IndexPath,
        secondary paint: Paint
    ) {
        stateMachine.selectSecondaryColor(color: paint)
    }
    
    func paintPickerViewDidScroll(_ paintPicker: PaintPickerView, primary paint: Paint) {
    }

    func paintPickerViewDidScroll(_ paintPicker: PaintPickerView, secondary paint: Paint) {
        stateMachine.selectSecondaryColor(color: paint)
    }

    func secondaryPaintPickerView(_ paintPicker: PaintPickerView, dismiss: Bool) {
    }
}

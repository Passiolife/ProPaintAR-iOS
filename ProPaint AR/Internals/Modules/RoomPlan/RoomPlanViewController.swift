//
//  RoomPlanViewController.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 3/1/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import ARKit
import Bugsnag
import Combine
import Foundation
import Kingfisher
import RemodelAR
import UIKit

@available(iOS 16, *)
protocol RoomPlanViewControllerDelegate: AnyObject {
    func dismiss(_ controller: RoomPlanViewController)
    func showOcclusionWizard(_ controller: RoomPlanViewController)
    func showLidarOcclusionWizard(_ controller: RoomPlanViewController)
    func showCart(paintInfo: PaintInfo, controller: RoomPlanViewController)
    func retrievedWallColorSample(color: UIColor, controller: RoomPlanViewController)
    func resetTriggered()
}

@available(iOS 16, *)
class RoomPlanViewController: UIViewController, Trackable {
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var tutorialTitle: UILabel!
    @IBOutlet weak var tutorialContent: UILabel!
    @IBOutlet weak var tutorialOkButton: UIButton!
    
    @IBOutlet weak var uiControls: UIStackView!
    @IBOutlet weak var cartButton: ImageButton!
    @IBOutlet weak var homeButton: ImageButton!
    @IBOutlet weak var doneScanningButton: RoundedButton!
    @IBOutlet weak var doneReviewingButton: RoundedButton!
    @IBOutlet weak var occlusionsButton: ImageButton!
    @IBOutlet weak var saveImageButton: ImageButton!
    @IBOutlet weak var userInstructions: PaddedTextView!
    @IBOutlet weak var colorPicker: PaintPickerView?
    @IBOutlet weak var userHint: PaddedTextView!
    @IBOutlet private weak var sceneResetButton: ImageButton!
    @IBOutlet weak var showUnpaintedWallsButton: ImageButton!
    @IBOutlet weak var exportRoomButton: RoundedButton!
    @IBOutlet weak var reviewingScanStackView: UIStackView!
    @IBOutlet weak var deleteWallButton: ImageButton!
    @IBOutlet weak var lidarOcclusionScanButton: ImageButton!
    
    @IBOutlet weak var toggleEditOcclusionsButton: ImageButton!
    @IBOutlet weak var deleteOcclusionButton: ImageButton!
    @IBOutlet weak var doneEditingOcclusionsButton: RoundedButton!
    @IBOutlet weak var occlusionButtonsView: UIView!
    @IBOutlet weak var patchCancelButton: RoundedButton!
    
    weak var delegate: RoomPlanViewControllerDelegate?
    private var arController: ARController?
    private var cancellables = Set<AnyCancellable>()
    private var arscnView: ARSCNView?
    private var lastOcclusionUpdate = Date()
    private var occlusionUpdateTimer: Timer?
    private var hasShownFullUI = false
    private var localData: LocalData! // swiftlint:disable:this implicitly_unwrapped_optional
    private var stateMachine = RoomPlanStateMachine()
    private var lastState: RoomPlanStateMachine.State = .fullUI
    private var currentWallId: UUID?
    private var isShowingCart = false
    
    private var patchState: PatchState = .editing {
        didSet {
            updateView(viewModel: stateMachine.statePublisher)
        }
    }
    private var isEditPatchSelected = false {
        didSet {
            updateView(viewModel: stateMachine.statePublisher)
        }
    }
    
    private var currentPaint: Paint? {
        didSet {
            guard let paint = currentPaint
            else { return }
            
            arController?.setColor(paint: paint.wallPaint, texture: paint.texture)
        }
    }
    
    private var showUnpaintedWalls = true {
        didSet {
            if showUnpaintedWalls {
                trackEvent(name: "roomplan show unpainted", parameters: nil)
            } else {
                trackEvent(name: "roomplan hide unpainted", parameters: nil)
            }
            applyUICustomization()
            arController?.showUnpaintedWalls(visible: showUnpaintedWalls)
        }
    }
    
    private var paints: [Paint] = [] {
        didSet {
            colorPicker?.reloadPicker()
        }
    }
    
    private var coachingVisible = false {
        didSet {
            updateView(viewModel: stateMachine.statePublisher)
        }
    }
    
    private var scannedLength: Float = 0 {
        didSet {
            stateMachine.scanUpdated(numWalls: scannedPlanes, totalLength: scannedLength)
            updateView(viewModel: stateMachine.statePublisher)
        }
    }
    
    private var scannedPlanes: Int = 0 {
        didSet {
            stateMachine.scanUpdated(numWalls: scannedPlanes, totalLength: scannedLength)
            updateView(viewModel: stateMachine.statePublisher)
        }
    }
    
    var customizationRepo: CustomizationRepo?
    var unscannedColor: UIColor?
    var unscannedBrightness: Float = -0.1

    internal static func instantiate(localData: LocalData) -> Self {
        let vc = Self.instantiate(fromStoryboardNamed: .ARMethods)
        vc.localData = localData
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureObservers()
        configureLocalData()
        configurePaintPicker()
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: Started")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        configureStateMachine()
        
        if isMovingToParent {
            trackTime(event: "roomplan paint success")
            trackTime(event: "roomplan closed")
            trackScreen(name: "roomplan", parameters: nil)
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
            trackEvent(name: "roomplan closed", parameters: nil)
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
    
    @IBAction func deleteWallAction(_ sender: Any) {
        arController?.deleteWall(id: currentWallId)
    }
    
    @IBAction func occlusionWizardTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: show occlusion wizard")
        stateMachine.showOcclusionWizard()
    }
    
    @IBAction func lidarOcclusionWizardTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: show lidar occlusion wizard")
        stateMachine.showLidarOcclusionWizard()
    }
    
    @IBAction func editOcclusionsAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: start editing occlusions")
        stateMachine.toggleEditingOcclusions()
    }
    
    @IBAction func doneEditingOcclusionsAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: done editing occlusions")
        stateMachine.toggleEditingOcclusions()
    }
    
    @IBAction func deleteOcclusionAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: delete occlusion")
        arController?.deleteSelectedPatch()
    }
    
    @IBAction func addPatchAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: add patch")
        arController?.addEditPatch(type: .add)
    }
    
    @IBAction func addOcclusionAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: add occlusion")
        arController?.addEditPatch(type: .remove)
    }
    
    @IBAction func cancelPatchAction(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: cancel patch")
        arController?.cancelEditPatch()
    }
}

@available(iOS 16, *)
private typealias StateMachine = RoomPlanViewController
@available(iOS 16, *)
extension StateMachine {
    private func configureStateMachine() {
        stateMachine.startedRoomPlanScan = { [weak self] in
            Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: started scan")
            self?.trackEvent(name: "roomplan started scan", parameters: nil)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.arController?.startRoomPlanScan(resetScene: true)
//            }
        }
        
        stateMachine.finishedRoomPlanScan = { [weak self] in
            guard let self = self else { return }

            Bugsnag.leaveBreadcrumb(withMessage: "Ro omPlan: finished scan")
            self.trackEvent(name: "roomplan finished scan", parameters: nil)
            self.arController?.finishRoomPlanScan()
        }
        
        stateMachine.finishedReviewing = { [weak self] in
            guard let self = self else { return }
            
            Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: finished reviewing")
            self.trackEvent(name: "roomplan finished reviewing", parameters: nil)
            self.colorPicker?.reloadPicker()
            self.arController?.finishRoomPlanReview()
            if let paint = self.currentPaint {
                self.arController?.setColor(paint: paint.wallPaint, texture: paint.texture)
            }
        }
        
        stateMachine.selectedSecondaryColor = { [weak self] color in
            self?.currentPaint = color
        }
        
        stateMachine.sceneReset = { [weak self] in
            self?.coachingVisible = false
            self?.hasShownFullUI = false
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
        
        stateMachine.showOcclusionWizardAction = { [weak self] in
            guard let self = self else { return }
            
            delegate?.showOcclusionWizard(self)
        }
        
        stateMachine.showLidarOcclusionWizardAction = { [weak self] in
            guard let self = self else { return }
            
            delegate?.showLidarOcclusionWizard(self)
        }
        stateMachine.updateEditingOcclusions = { [weak self] editing in
            guard let self = self else { return }
            
            self.arController?.setPatchEditing(enabled: editing)
        }
    }
}

@available(iOS 16, *)
private typealias IBActions = RoomPlanViewController
@available(iOS 16, *)
extension IBActions {
    @IBAction func hideTutorialAction(_ sender: Any) {
        stateMachine.tutorialFinished()
    }
    
    @IBAction func doneScanningTapped(_ sender: Any) {
        stateMachine.doneScanning()
    }
    
    @IBAction func finishReviewTapped(_ sender: Any) {
        stateMachine.finishReviewing()
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
            
            Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: save photo")
            self.trackEvent(name: "saved photo", parameters: nil)
            UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
            self.userHint.enqueueMessage(message: "Photo saved to album",
                                         duration: 2)
        }
    }
    
    @IBAction func resetTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: reset")
        trackEvent(name: "reset scene", parameters: nil)
        stateMachine.reset()
    }

    @IBAction func cartTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "RoomPlan: show cart")
        trackEvent(name: "show cart", parameters: nil)
        isShowingCart = true
        arController?.retrievePaintInfo()
        arController?.tearDown()
    }
    
    @IBAction func deselectWallsAction(_ sender: Any) {
        arController?.deselectMeshes()
    }
    
    @IBAction func toggleUnpaintedWallsVisible(_ sender: Any) {
        showUnpaintedWalls.toggle()
    }
    
    @IBAction func exportRoomAction(_ sender: Any) {
        arController?.save3DModel(callback: { url in
            guard let url = url else { return }
            
            if FileManager.default.fileExists(atPath: url.path) {
                let activityViewController = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                self.present(activityViewController, animated: true, completion: nil)
            }
        })
    }
}

@available(iOS 16, *)
private typealias Configuration = RoomPlanViewController
@available(iOS 16, *)
extension Configuration {
    public func setPaints(paints: [Paint]) {
        self.paints = paints
    }
    
    private func configureAR() {
        arController?.setRoomPlanOcclusionVisibility(enableAll2D: true, enableAll3D: false)
        
        if let color = unscannedColor {
            arController?.setUnpaintedColor(color: color, brightness: unscannedBrightness)
        }
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
                
                if self.stateMachine.statePublisher != self.lastState {
                    self.updateView(viewModel: viewModel)
                
                    switch self.stateMachine.statePublisher {
                    case .pickingColor:
                        self.trackScreen(name: "roomplan picking color", parameters: nil)
                        
                    case .paintingFirstWall:
                        self.trackScreen(name: "roomplan painting wall", parameters: nil)
                        
                    case .fullUI:
                        self.trackEvent(name: "roomplan paint success", parameters: nil)
                        
                    default:
                        break
                    }
                }
                self.lastState = self.stateMachine.statePublisher
            }
            .store(in: &cancellables)
    }
    
    private func updateView(viewModel: RoomPlanStateMachine.State) {
        if viewModel.isWizardVisible {
            hideAllUI()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                var hideDeleteOcclusionButton = !(viewModel.editingOcclusions && self.isEditPatchSelected)
                var hideOcclusionButtons = !viewModel.editingOcclusions
                let hideOcclusionEdit = !(viewModel.uiControlsVisible && self.currentWallId != nil)
                if patchState == .adding {
                    hideOcclusionButtons = true
                    hideDeleteOcclusionButton = true
                }
                self.patchCancelButton.isHidden = patchState != .adding
                self.occlusionButtonsView.isHidden = hideOcclusionButtons
                self.deleteOcclusionButton.isHidden = hideDeleteOcclusionButton
                self.toggleEditOcclusionsButton.isHidden = hideOcclusionEdit
                self.reviewingScanStackView.isHidden = !viewModel.reviewingScan
                self.doneScanningButton.isHidden = !viewModel.doneScanningButtonVisible
                self.showUnpaintedWallsButton.isHidden = !viewModel.uiControlsVisible
                self.lidarOcclusionScanButton.isHidden = !viewModel.uiControlsVisible
                self.deleteWallButton.isHidden = !(self.currentWallId != nil &&
                                                   viewModel.uiControlsVisible)
                self.tutorialView.isHidden = !viewModel.tutorialVisible
                self.uiControls.isHidden = !viewModel.uiControlsVisible
                self.cartButton.isHidden = !viewModel.cartButtonVisible
                self.colorPicker?.isHidden = !viewModel.colorPickerVisible
                self.userInstructions.isHidden = !viewModel.userInstructionsVisible
                self.userInstructions.text = viewModel.userInstructions
                if let userHintMessage = viewModel.userHint {
                    self.userHint.enqueueMessage(message: userHintMessage)
                }
            }
        }
    }
    private func hideAllUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.patchCancelButton.isHidden = true
            self.occlusionButtonsView.isHidden = true
            self.toggleEditOcclusionsButton.isHidden = true
            self.deleteOcclusionButton.isHidden = true
            self.reviewingScanStackView.isHidden = true
            self.doneScanningButton.isHidden = true
            self.showUnpaintedWallsButton.isHidden = true
            self.lidarOcclusionScanButton.isHidden = true
            self.deleteWallButton.isHidden = true
            self.tutorialView.isHidden = true
            self.uiControls.isHidden = true
            self.cartButton.isHidden = true
            self.colorPicker?.isHidden = true
            self.userInstructions.isHidden = true
        }
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
        if !ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            print("lidar not supported")
        } else {
            createARView()
            configureBindings()
            
            // This call to resetScene normally wouldn't be necessary, but is required until we can track down an issue that occurs on some versions of iOS.
            arController?.resetScene()
        }
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
        trackEvent(name: "app moved to background", parameters: nil)
        arController?.pauseScene()
    }

    @objc private func appMovedToForeground() {
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
        
        arController = RemodelARLib.makeRoomPlanARController(with: arscnView)
    }
    
    private func configureBindings() {
        arController?.wallPainted = { [weak self] in
            var parameters: [String: Any]?
            if let currentPaint = self?.currentPaint {
                self?.stateMachine.selectSecondaryColor(color: currentPaint)
                parameters = ["color": currentPaint.color.toHexString()]
            }
            self?.trackEvent(name: "roomplan wall painted", parameters: parameters)
            self?.stateMachine.paintFirstWall()
        }
//        arController?.trackingReady = { isReady in
//            print("tracking ready: \(isReady ? "true" : "false")")
//        }
        arController?.retrievedWallColorSample = { [weak self] color in
            guard let self = self else { return }

            self.delegate?.retrievedWallColorSample(color: color, controller: self)
        }
        arController?.planarMeshCountUpdated = { [weak self] planeCount in
            guard let self = self else { return }
            
            self.scannedPlanes = planeCount
        }
        arController?.roomPlanScannedLengthUpdated = { [weak self] totalLength in
            self?.scannedLength = totalLength
        }
        arController?.currentSelectedWallId = { [weak self] id in
            guard let self = self else { return }
            
            self.currentWallId = id
            self.updateView(viewModel: self.stateMachine.statePublisher)
        }
        arController?.isEditPatchSelected = { [weak self] isSelected in
            self?.isEditPatchSelected = isSelected
        }
        arController?.patchStateChanged = { [weak self] state in
            self?.patchState = state
        }
        arController?.roomPlanFailed = { [weak self] error in
            if error == .worldTrackingFailure {
                DispatchQueue.main.async {
                    self?.arController?.startRoomPlanScan(resetScene: true)
                }
            }
        }
        arController?.retrievedPaintInfo = { [weak self] paintInfo in
            guard let self = self,
                  self.isShowingCart
            else { return }
            
            self.delegate?.showCart(paintInfo: paintInfo, controller: self)
        }
//        arController?.roomPlanInstructionUpdated = { [weak self] instruction in
//
//        }
//        arController?.analyticsTracking = { event in
//            print("event: \(event.analyticsData.event)")
//        }
    }

    private func applyUICustomization() {
        if let customizationRepo = customizationRepo {
            let uiOptions = customizationRepo.options.uiOptions
            let arOptions = customizationRepo.options.arOptions
            let textColor = uiOptions.colors.text.color
            let resetIcon = uiOptions.buttonIcons.resetSceneIcon
            let saveImageIcon = uiOptions.buttonIcons.saveImageIcon
            let occlusionsIcon = uiOptions.buttonIcons.shaderOcclusionsIcon
            let homeIcon = uiOptions.buttonIcons.homeIcon
            let cartIcon = uiOptions.buttonIcons.shoppingCartIcon
            let hideIcon = uiOptions.buttonIcons.hideFloorplanUnpaintedIcon
            let showIcon = uiOptions.buttonIcons.showFloorplanUnpaintedIcon
            let scanStyleRaw = arOptions.lidar.scanStyle.rawInt
            if let scanStyle = LidarScanStyle(rawValue: scanStyleRaw) {
                arController?.setLidarScanStyle(scanStyle: scanStyle)
            }
            
            sceneResetButton.imageView.setImage(with: resetIcon, placeholder: nil)
            occlusionsButton.imageView.setImage(with: occlusionsIcon, placeholder: nil)
            saveImageButton.imageView.setImage(with: saveImageIcon, placeholder: nil)
            homeButton.imageView.setImage(with: homeIcon, placeholder: nil)
            cartButton.imageView.setImage(with: cartIcon, placeholder: nil)
            
            unscannedColor = arOptions.lidar.unscannedColor
            unscannedBrightness = arOptions.lidar.unscannedBrightness
            arController?.setUnpaintedColor(color: arOptions.lidar.unscannedColor,
                                            brightness: arOptions.lidar.unscannedBrightness)
            arController?.setSelectedColor(color: arOptions.lidar.selectedColor)
            
            let userInstructionFont = uiOptions.font.font(with: 16)
            userInstructions.setFont(font: userInstructionFont)
            userInstructions.textColor = textColor
            
            let userHintFont = uiOptions.font.font(with: 16)
            userHint.setFont(font: userHintFont)
            userHint.textColor = textColor
            
            let primaryFont = uiOptions.font.font(with: 16)
            let secondaryFont = uiOptions.font.font(with: 16)
            colorPicker?.configurePrimaryTitleLabelStyle(primaryFont, textColor)
            colorPicker?.configureSecondaryTitleLabelStyle(secondaryFont, textColor)
            
            let tutorialTitleFont = uiOptions.font.font(with: 18)
            let tutorialBodyFont = uiOptions.font.font(with: 14)
            tutorialTitle.font = tutorialTitleFont
            tutorialContent.font = tutorialBodyFont
            tutorialOkButton.titleLabel?.font = uiOptions.font.font(with: 14)
            tutorialTitle.textColor = textColor
            tutorialContent.textColor = textColor
            tutorialOkButton.setTitleColor(textColor, for: .normal)
            
            if showUnpaintedWalls {
                showUnpaintedWallsButton.imageView.setImage(with: showIcon)
            } else {
                showUnpaintedWallsButton.imageView.setImage(with: hideIcon)
            }
        } else {
            if showUnpaintedWalls {
                showUnpaintedWallsButton.iconImage = UIImage(systemName: "eye.fill")
            } else {
                showUnpaintedWallsButton.iconImage = UIImage(systemName: "eye.slash.fill")
            }
        }
    }
}

@available(iOS 16, *)
private typealias Gestures = RoomPlanViewController
@available(iOS 16, *)
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

@available(iOS 16, *)
private typealias PaintPickerData = RoomPlanViewController
@available(iOS 16, *)
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

@available(iOS 16, *)
private typealias PaintPickerDelegateCallbacks = RoomPlanViewController
@available(iOS 16, *)
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
        currentPaint = nil
    }
}

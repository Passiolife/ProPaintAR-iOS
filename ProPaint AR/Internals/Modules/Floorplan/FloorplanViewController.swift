//
//  FloorplanViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/25/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import ARKit
import Bugsnag
import Combine
import Foundation
import Kingfisher
import RemodelAR
import UIKit

protocol FloorplanViewControllerDelegate: AnyObject {
    func dismiss(_ controller: FloorplanViewController)
    func showOcclusionWizard(_ controller: FloorplanViewController)
    func showLidarOcclusionWizard(_ controller: FloorplanViewController)
    func showCart(paintInfo: PaintInfo, controller: FloorplanViewController)
    func retrievedWallColorSample(color: UIColor, controller: FloorplanViewController)
    func resetTriggered()
}

class FloorplanViewController: UIViewController, Trackable {
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
    @IBOutlet weak var scanOverlay: UIView!
    @IBOutlet weak var finishButton: RoundedButton!
    @IBOutlet weak var setHeightButton: RoundedButton!
    @IBOutlet weak var showUnpaintedWallsButton: ImageButton!
    @IBOutlet private weak var sceneResetButton: ImageButton!
    @IBOutlet weak var scanOverlayText: UITextView!
    @IBOutlet weak var showOcclusionsButton: ImageButton!
    @IBOutlet weak var saveImageButton: ImageButton!
    @IBOutlet weak var deleteWallButton: ImageButton!
    @IBOutlet weak var lidarOcclusionScanButton: ImageButton!
    
    weak var delegate: FloorplanViewControllerDelegate?
    private var arController: ARController?
    private var cancellables = Set<AnyCancellable>()
    private var arscnView: ARSCNView?
    private var lastOcclusionUpdate = Date()
    private var occlusionUpdateTimer: Timer?
    private var localData: LocalData! // swiftlint:disable:this implicitly_unwrapped_optional
    private var stateMachine = FloorplanStateMachine()
    private var lastState: FloorplanStateMachine.State = .fullUI
    private var currentWallId: UUID?
    private var isShowingCart = false
    
    var customizationRepo: CustomizationRepo?
    var selectedColor: UIColor?
    var unpaintedColor: UIColor?
    var unpaintedBrightness: Float = -0.1

    private var showUnpaintedWalls = true {
        didSet {
            if showUnpaintedWalls {
                trackEvent(name: "floorplan show unpainted", parameters: nil)
            } else {
                trackEvent(name: "floorplan hide unpainted", parameters: nil)
            }
            applyUICustomization()
            arController?.showUnpaintedWalls(visible: showUnpaintedWalls)
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
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: Started")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isMovingToParent {
            trackTime(event: "floorplan closed")
            trackTime(event: "floorplan paint success")
            trackScreen(name: "floorplan", parameters: nil)
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
            trackEvent(name: "floorplan closed", parameters: nil)
        }
        unconfigureView()
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
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: show occlusion wizard")
        stateMachine.showOcclusionWizard()
    }
    
    @IBAction func lidarOcclusionWizardTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: show lidar occlusion wizard")
        stateMachine.showLidarOcclusionWizard()
    }
}

private typealias StateMachine = FloorplanViewController
extension StateMachine {
    private func configureStateMachine() {
        stateMachine.startScan = { [weak self] in
            self?.arController?.startFloorScan(timeout: 6)
        }
        
        stateMachine.finishedPlacingCorners = { [weak self] closedShape in
            if !closedShape {
                self?.arController?.finishCorners(closeShape: false)
            }
        }
        
        stateMachine.finishedCeilingHeight = { [weak self] in
            guard let self = self else { return }
            
            self.arController?.finishHeight()
            self.colorPicker?.reloadPicker()
            if let currentPaint = self.currentPaint {
                self.currentPaint = currentPaint
            }
        }
        
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
            self?.arController?.startScene(reset: true)
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
    }
}

private typealias IBActions = FloorplanViewController
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
            
            Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: save photo")
            self.trackEvent(name: "saved photo", parameters: nil)
            UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
            self.userHint.enqueueMessage(message: "Photo saved to album",
                                         duration: 2)
        }
    }
    
    @IBAction func resetTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: reset")
        trackEvent(name: "reset scene", parameters: nil)
        stateMachine.reset()
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: finished corners")
        stateMachine.finishPlacingCorners(closedShape: false)
    }
    
    @IBAction func setHeightTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: finished height")
        stateMachine.setHeight()
    }
    
    @IBAction func cartTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: show cart")
        trackEvent(name: "show cart", parameters: nil)
        isShowingCart = true
        arController?.retrievePaintInfo()
        arController?.pauseScene()
    }
    
    @IBAction func toggleUnpaintedWallsVisible(_ sender: Any) {
        showUnpaintedWalls.toggle()
    }
}

private typealias Configuration = FloorplanViewController
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
                
                if self.stateMachine.statePublisher != self.lastState {
                    self.updateView(viewModel: viewModel)
                
                    switch self.stateMachine.statePublisher {
                    case .tutorial:
                        self.trackScreen(name: "floorplan tutorial", parameters: nil)
                        
                    case .scanning:
                        self.trackScreen(name: "floorplan scanning", parameters: nil)
                        
                    case .placingCorners:
                        self.trackScreen(name: "floorplan placing corners", parameters: nil)
                        
                    case .settingHeight:
                        self.trackScreen(name: "floorplan setting height", parameters: nil)
                        
                    case .pickingColor:
                        self.trackScreen(name: "floorplan picking color", parameters: nil)
                        
                    case .paintingFirstWall:
                        self.trackScreen(name: "floorplan painting first wall", parameters: nil)
                        
                    case .fullUI:
                        self.trackEvent(name: "floorplan paint success", parameters: nil)
                        
                    default: break
                    }
                }
                self.lastState = self.stateMachine.statePublisher
            }
            .store(in: &cancellables)
    }
    
    private func updateView(viewModel: FloorplanStateMachine.State) {
        if viewModel.isWizardVisible {
            hideAllUI()
        } else {
            lidarOcclusionScanButton.isHidden = !viewModel.uiControlsVisible
            deleteWallButton.isHidden = !(currentWallId != nil && viewModel.uiControlsVisible)
            tutorialView.isHidden = !viewModel.tutorialVisible
            uiControls.isHidden = !viewModel.uiControlsVisible
            cartButton.isHidden = !viewModel.cartButtonVisible
            colorPicker?.isHidden = !viewModel.colorPickerVisible
            scanOverlay.isHidden = !viewModel.scanOverlayVisible
            showUnpaintedWallsButton.isHidden = !viewModel.hideUnpaintedWallsButtonVisible
            finishButton.isHidden = !viewModel.finishButtonVisible
            setHeightButton.isHidden = !viewModel.setHeightButtonVisible
            userInstructions.isHidden = !viewModel.userInstructionsVisible
            userInstructions.text = viewModel.userInstructions
            userHint.isHidden = !viewModel.userHintVisible
            if let userHintMessages = viewModel.userHint {
                userHint.enqueueMessages(messages: userHintMessages)
            }
        }
    }
    
    private func hideAllUI() {
        lidarOcclusionScanButton.isHidden = true
        deleteWallButton.isHidden = true
        tutorialView.isHidden = true
        uiControls.isHidden = true
        cartButton.isHidden = true
        colorPicker?.isHidden = true
        scanOverlay.isHidden = true
        showUnpaintedWallsButton.isHidden = true
        finishButton.isHidden = true
        setHeightButton.isHidden = true
        userInstructions.isHidden = true
        userHint.isHidden = true
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
        finishButton.fixTextAlignment()
        setHeightButton.fixTextAlignment()
    }
    
    private func unconfigureView() {
        occlusionUpdateTimer?.invalidate()
        arController = nil
        arscnView?.removeFromSuperview()
        arscnView = nil
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
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: app backgrounded")
        trackEvent(name: "app moved to background", parameters: nil)
        arController?.pauseScene()
    }

    @objc private func appMovedToForeground() {
        Bugsnag.leaveBreadcrumb(withMessage: "Floorplan: app foregrounded")
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
        
        arController = RemodelARLib.makeFloorplanARController(with: arscnView)
    }
    
    private func configureBindings() {
        arController?.wallPainted = { [weak self] in
            var parameters: [String: Any]?
            if let currentPaint = self?.currentPaint {
                self?.stateMachine.selectSecondaryColor(color: currentPaint)
                parameters = ["color": currentPaint.color.toHexString()]
            }
            self?.trackEvent(name: "floorplan wall painted", parameters: parameters)
            self?.stateMachine.paintFirstWall()
        }
        arController?.trackingReady = { [weak self] isReady in
            guard isReady else { return }
            
            self?.stateMachine.scanFinished()
        }
        arController?.retrievedWallColorSample = { [weak self] color in
            guard let self = self else { return }

            self.delegate?.retrievedWallColorSample(color: color, controller: self)
        }
        arController?.floorplanCornerCountUpdated = { [weak self] cornerCount in
            self?.stateMachine.updateCornerCount(cornerCount: cornerCount)
        }
        arController?.floorplanShapeClosed = { [weak self] in
            self?.stateMachine.finishPlacingCorners(closedShape: true)
        }
        arController?.isWallSelected = { isSelected in
            print("isSelected: \(isSelected)")
        }
        arController?.currentSelectedWallId = { [weak self] id in
            guard let self = self else { return }
            
            self.currentWallId = id
            self.deleteWallButton.isHidden = id == nil
        }
        arController?.retrievedPaintInfo = { [weak self] paintInfo in
            guard let self = self,
                  self.isShowingCart
            else { return }
            
            self.delegate?.showCart(paintInfo: paintInfo, controller: self)
        }
        
//        arController?.analyticsTracking = { event in
//            print("event: \(event.analyticsData.event)")
//        }
    }
    
    private func applyUICustomization() {
        if let customizationRepo = customizationRepo {
            let uiOptions = customizationRepo.options.uiOptions
            let arOptions = customizationRepo.options.arOptions
            let resetIcon = uiOptions.buttonIcons.resetSceneIcon
            let saveImageIcon = uiOptions.buttonIcons.saveImageIcon
            let occlusionsIcon = uiOptions.buttonIcons.shaderOcclusionsIcon
            let homeIcon = uiOptions.buttonIcons.homeIcon
            let cartIcon = uiOptions.buttonIcons.shoppingCartIcon
            let hideIcon = uiOptions.buttonIcons.hideFloorplanUnpaintedIcon
            let showIcon = uiOptions.buttonIcons.showFloorplanUnpaintedIcon
            let textColor = uiOptions.colors.text.color
            
            sceneResetButton.imageView.setImage(with: resetIcon, placeholder: nil)
            showOcclusionsButton.imageView.setImage(with: occlusionsIcon, placeholder: nil)
            saveImageButton.imageView.setImage(with: saveImageIcon, placeholder: nil)
            homeButton.imageView.setImage(with: homeIcon, placeholder: nil)
            cartButton.imageView.setImage(with: cartIcon, placeholder: nil)
            
            selectedColor = arOptions.floorplan.selectedColor
            unpaintedColor = arOptions.floorplan.unpaintedWallColor
            unpaintedBrightness = arOptions.floorplan.unpaintedWallBrightness
            arController?.setUnpaintedColor(color: arOptions.floorplan.unpaintedWallColor,
                                            brightness: arOptions.floorplan.unpaintedWallBrightness)
            
            userInstructions.setFont(font: uiOptions.font.font(with: 16),
                                     color: uiOptions.colors.text.color)
            
            userHint.setFont(font: uiOptions.font.font(with: 16),
                             color: uiOptions.colors.text.color)
            setHeightButton.titleLabel?.font = uiOptions.font.font(with: 16)
            setHeightButton.setTitleColor(uiOptions.colors.text.color, for: .normal)
            finishButton.titleLabel?.font = uiOptions.font.font(with: 16)
            finishButton.setTitleColor(uiOptions.colors.text.color, for: .normal)
            scanOverlayText.font = uiOptions.font.font(with: 16)
            scanOverlayText.textColor = uiOptions.colors.text.color
            
            let primaryFont = uiOptions.font.font(with: 16)
            let secondaryFont = uiOptions.font.font(with: 16)
            colorPicker?.configurePrimaryTitleLabelStyle(primaryFont,
                                                         uiOptions.colors.text.color)
            colorPicker?.configureSecondaryTitleLabelStyle(secondaryFont,
                                                           uiOptions.colors.text.color)
            
            if showUnpaintedWalls {
                showUnpaintedWallsButton.imageView.setImage(with: showIcon)
            } else {
                showUnpaintedWallsButton.imageView.setImage(with: hideIcon)
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
            if showUnpaintedWalls {
                showUnpaintedWallsButton.iconImage = UIImage(systemName: "eye.fill")
            } else {
                showUnpaintedWallsButton.iconImage = UIImage(systemName: "eye.slash.fill")
            }
        }
    }
}

private typealias Gestures = FloorplanViewController
extension Gestures {
    private func addGestureOnARView() {
        let undoGesture = UISwipeGestureRecognizer(target: self, action: #selector(onUndoSwipeARView(_:)))
        undoGesture.direction = .left
        undoGesture.numberOfTouchesRequired = 1
        arscnView?.addGestureRecognizer(undoGesture)
        
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(onDraggingARView(_:)))
        dragGesture.require(toFail: undoGesture)
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
    
    @objc private func onUndoSwipeARView(_ sender: UISwipeGestureRecognizer) {
        arController?.removeLastCorner()
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first
        else { return }
        let point = touch.location(in: arscnView)
        arController?.handleTouch(point: point)
    }
}

private typealias PaintPickerData = FloorplanViewController
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

private typealias PaintPickerDelegateCallbacks = FloorplanViewController
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

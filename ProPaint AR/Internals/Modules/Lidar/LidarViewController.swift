//
//  LidarViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import ARKit
import Bugsnag
import Combine
import Foundation
import Kingfisher
import RemodelAR
import UIKit

protocol LidarViewControllerDelegate: AnyObject {
    func dismiss(_ controller: LidarViewController)
    func showOcclusionWizard(_ controller: LidarViewController)
    func showCart(paintInfo: PaintInfo, controller: LidarViewController)
    func retrievedWallColorSample(color: UIColor, controller: LidarViewController)
    func resetTriggered()
}

class LidarViewController: UIViewController, Trackable {
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var tutorialTitle: UILabel!
    @IBOutlet weak var tutorialContent: UILabel!
    @IBOutlet weak var tutorialOkButton: UIButton!
    
    @IBOutlet weak var uiControls: UIStackView!
    @IBOutlet weak var cartButton: ImageButton!
    @IBOutlet weak var homeButton: ImageButton!
    @IBOutlet weak var scanButton: ActivitySpinnerButton!
    @IBOutlet weak var occlusionsButton: ImageButton!
    @IBOutlet weak var saveImageButton: ImageButton!
    @IBOutlet weak var userInstructions: PaddedTextView!
    @IBOutlet weak var colorPicker: PaintPickerView?
    @IBOutlet weak var userHint: PaddedTextView!
    @IBOutlet private weak var sceneResetButton: ImageButton!
    @IBOutlet weak var deselectWallsButton: ImageButton!
    @IBOutlet weak var deleteWallButton: ImageButton!
    
    weak var delegate: LidarViewControllerDelegate?
    private var arController: ARController?
    private var cancellables = Set<AnyCancellable>()
    private var arscnView: ARSCNView?
    private var lastOcclusionUpdate = Date()
    private var occlusionUpdateTimer: Timer?
    private var planeCount: Int = 0
    private var hasShownFullUI = false
    private var localData: LocalData! // swiftlint:disable:this implicitly_unwrapped_optional
    private var stateMachine = LidarStateMachine()
    private var lastState: LidarStateMachine.State = .fullUI
    private var currentWallId: UUID?
    private var isShowingCart = false
    
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
        Bugsnag.leaveBreadcrumb(withMessage: "Lidar: Started")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        configureStateMachine()
        
        if isMovingToParent {
            trackTime(event: "lidar paint success")
            trackTime(event: "lidar closed")
            trackScreen(name: "lidar", parameters: nil)
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
            trackEvent(name: "lidar closed", parameters: nil)
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
    }
}

private typealias StateMachine = LidarViewController
extension StateMachine {
    private func configureStateMachine() {
        stateMachine.startedLidarScan = { [weak self] in
            Bugsnag.leaveBreadcrumb(withMessage: "Lidar: started scan")
            self?.trackEvent(name: "lidar started scan", parameters: nil)
            self?.arController?.startLidarScan()
        }
        
        stateMachine.finishedLidarScan = { [weak self] in
            guard let self = self else { return }
            
            Bugsnag.leaveBreadcrumb(withMessage: "Lidar: finished scan")
            self.trackEvent(name: "lidar finished scan", parameters: nil)
            self.colorPicker?.reloadPicker()
            self.arController?.stopLidarScan()
            if let currentPaint = self.currentPaint {
                self.currentPaint = currentPaint
            }
        }
        
        stateMachine.selectedSecondaryColor = { [weak self] color in
            self?.currentPaint = color
        }
        
        stateMachine.sceneReset = { [weak self] in
            self?.planeCount = 0
            self?.hasShownFullUI = false
            self?.userHint.clearQueue()
            self?.delegate?.resetTriggered()
            self?.arController?.resetScene(startMode: .paused)
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
    }
}

private typealias IBActions = LidarViewController
extension IBActions {
    @IBAction func hideTutorialAction(_ sender: Any) {
        stateMachine.tutorialFinished()
    }
    
    @IBAction func scanButtonTapped(_ sender: Any) {
        stateMachine.scanButtonTapped(planeCount: planeCount)
        if let color = currentPaint {
            stateMachine.selectSecondaryColor(color: color)
        }
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
            
            Bugsnag.leaveBreadcrumb(withMessage: "Lidar: save photo")
            self.trackEvent(name: "saved photo", parameters: nil)
            UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
            self.userHint.enqueueMessage(message: "Photo saved to album",
                                         duration: 2)
        }
    }
    
    @IBAction func resetTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Lidar: reset")
        trackEvent(name: "reset scene", parameters: nil)
        stateMachine.reset()
    }
    
    @IBAction func occlusionWizardTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Lidar: show occlusion wizard")
        delegate?.showOcclusionWizard(self)
    }

    @IBAction func showCartTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Lidar: show cart")
        trackEvent(name: "show cart", parameters: nil)
        isShowingCart = true
        arController?.retrievePaintInfo()
        arController?.pauseScene()
    }
    
    @IBAction func deselectWallsAction(_ sender: Any) {
        arController?.deselectMeshes()
    }
    
    @IBAction func deleteWallAction(_ sender: Any) {
        arController?.deleteWall(id: currentWallId)
    }
}

private typealias Configuration = LidarViewController
extension Configuration {
    public func setPaints(paints: [Paint]) {
        self.paints = paints
    }
    
    private func configureAR() {
        arController?.toggleLidarOutline(visible: true)
        arController?.setLidarOutlineStyle(style: .shader(thickness: 10))
        arController?.setOcclusionDepthThreshold(threshold: 0.05)
        
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
                        self.trackScreen(name: "lidar picking color", parameters: nil)
                        
                    case .paintingFirstWall:
                        self.trackScreen(name: "lidar painting wall", parameters: nil)
                        
                    case .fullUI:
                        self.trackEvent(name: "lidar paint success", parameters: nil)
                        
                    default:
                        break
                    }
                }
                self.lastState = self.stateMachine.statePublisher
            }
            .store(in: &cancellables)
    }
    
    private func updateView(viewModel: LidarStateMachine.State) {
        tutorialView.isHidden = !viewModel.tutorialVisible
        scanButton.isHidden = !viewModel.scanButtonVisible
        scanButton.isAnimating = viewModel.scanButtonAnimating
        scanButton.buttonTitle = viewModel.scanButtonTitle
        uiControls.isHidden = !viewModel.uiControlsVisible
        cartButton.isHidden = !viewModel.cartButtonVisible
        colorPicker?.isHidden = !viewModel.colorPickerVisible
        userInstructions.isHidden = !viewModel.userInstructionsVisible
        userInstructions.text = viewModel.userInstructions
        deselectWallsButton.isHidden = !viewModel.uiControlsVisible
        if let userHintMessage = viewModel.userHint {
            userHint.enqueueMessage(message: userHintMessage)
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
            arController?.startScene(reset: true)
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
        
        arController = RemodelARLib.makeLidarARController(with: arscnView)
    }
    
    private func configureBindings() {
        arController?.wallPainted = { [weak self] in
            var parameters: [String: Any]?
            if let currentPaint = self?.currentPaint {
                self?.stateMachine.selectSecondaryColor(color: currentPaint)
                parameters = ["color": currentPaint.color.toHexString()]
            }
            self?.trackEvent(name: "lidar wall painted", parameters: parameters)
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
            self?.planeCount = planeCount
        }
//        arController?.analyticsTracking = { event in
//            print("event: \(event.analyticsData.event)")
//        }
        arController?.isWallSelected = { [weak self] isWallSelected in
            guard let self = self else { return }
            
            let uiControlsVisible = self.stateMachine.statePublisher.uiControlsVisible
            let isHidden = !(uiControlsVisible && isWallSelected)
            self.deselectWallsButton.isHidden = isHidden
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
    }

    private func applyUICustomization() {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let arOptions = customizationRepo.options.arOptions
        let textColor = uiOptions.colors.text.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let resetIcon = uiOptions.buttonIcons.resetSceneIcon
        let saveImageIcon = uiOptions.buttonIcons.saveImageIcon
        let occlusionsIcon = uiOptions.buttonIcons.shaderOcclusionsIcon
        let homeIcon = uiOptions.buttonIcons.homeIcon
        let cartIcon = uiOptions.buttonIcons.shoppingCartIcon
        let hideWallsIcon = uiOptions.buttonIcons.hideFloorplanUnpaintedIcon
        let scanStyleRaw = arOptions.lidar.scanStyle.rawInt
        if let scanStyle = LidarScanStyle(rawValue: scanStyleRaw) {
            arController?.setLidarScanStyle(scanStyle: scanStyle)
        }
        
        sceneResetButton.imageView.setImage(with: resetIcon, placeholder: nil)
        occlusionsButton.imageView.setImage(with: occlusionsIcon, placeholder: nil)
        saveImageButton.imageView.setImage(with: saveImageIcon, placeholder: nil)
        homeButton.imageView.setImage(with: homeIcon, placeholder: nil)
        cartButton.imageView.setImage(with: cartIcon, placeholder: nil)
        deselectWallsButton.imageView.setImage(with: hideWallsIcon, placeholder: nil)
        
        unscannedColor = arOptions.lidar.unscannedColor
        unscannedBrightness = arOptions.lidar.unscannedBrightness
        arController?.setUnpaintedColor(color: arOptions.lidar.unscannedColor,
                                        brightness: arOptions.lidar.unscannedBrightness)
        arController?.setSelectedColor(color: arOptions.lidar.selectedColor)
        
        let scanFontSize = scanButton.buttonTitleFontSize
        let scanFont = uiOptions.font.font(with: scanFontSize)
        scanButton.setFont(font: scanFont)
        scanButton.buttonTitleColor = buttonTextColor
        
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
    }
}

private typealias Gestures = LidarViewController
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

private typealias PaintPickerData = LidarViewController
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

private typealias PaintPickerDelegateCallbacks = LidarViewController
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

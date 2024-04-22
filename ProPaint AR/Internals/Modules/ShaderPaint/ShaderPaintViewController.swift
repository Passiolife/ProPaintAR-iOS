//
//  ShaderPaintViewController.swift
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
import RemodelAR
import UIKit

protocol ShaderPaintViewControllerDelegate: AnyObject {
    func dismiss(_ controller: ShaderPaintViewController)
    func showOcclusionWizard(_ controller: ShaderPaintViewController)
    func showCart(paintInfo: PaintInfo, controller: ShaderPaintViewController)
    func retrievedWallColorSample(color: UIColor, controller: ShaderPaintViewController)
    func resetTriggered()
}

class ShaderPaintViewController: UIViewController, Trackable {
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var tutorialTitle: UILabel!
    @IBOutlet weak var tutorialContent: UILabel!
    @IBOutlet weak var tutorialOkButton: UIButton!
    
    @IBOutlet weak var uiControls: UIStackView!
    @IBOutlet weak var cartButton: ImageButton!
    @IBOutlet weak var homeButton: ImageButton!
    @IBOutlet weak var colorPicker: PaintPickerView?
    @IBOutlet weak var userHint: PaddedTextView!
    @IBOutlet weak var shaderOcclusionsButton: ImageButton!
    @IBOutlet private weak var sceneResetButton: ImageButton!
    @IBOutlet weak var saveImageButton: ImageButton!

    weak var delegate: ShaderPaintViewControllerDelegate?
    private var arController: ARController?
    private var cancellables = Set<AnyCancellable>()
    private var arscnView: ARSCNView?
    private var lastOcclusionUpdate = Date()
    private var occlusionUpdateTimer: Timer?
    private var localData: LocalData! // swiftlint:disable:this implicitly_unwrapped_optional
    private var stateMachine = ShaderPaintStateMachine()
    private var lastState: ShaderPaintStateMachine.State = .fullUI
    private var paintSuccess = false {
        didSet {
            if oldValue != paintSuccess {
                trackEvent(name: "shader paint success", parameters: nil)
            }
        }
    }
    private var hintColor: UIColor?
    private var hintFont: UIFont?
    private var hintIcon: UIImage?
        
    private var currentPaint: Paint?
    
    private var paints: [Paint] = [] {
        didSet {
            colorPicker?.reloadPicker()
        }
    }

    var customizationRepo: CustomizationRepo?

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
        Bugsnag.leaveBreadcrumb(withMessage: "Shader: Started")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureAR()
        configureView()
        applyUICustomization()
        updateView(viewModel: stateMachine.statePublisher)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isMovingToParent {
            trackTime(event: "shader paint closed")
            trackTime(event: "shader paint success")
            trackScreen(name: "shader paint", parameters: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            trackEvent(name: "shader paint closed", parameters: nil)
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

private typealias StateMachine = ShaderPaintViewController
extension StateMachine {
    private func configureStateMachine() {
        stateMachine.selectedSecondaryColor = { [weak self] color in
            self?.currentPaint = color
            self?.arController?.setColor(paint: color.wallPaint,
                                         texture: color.texture)
        }
                
        stateMachine.sceneReset = { [weak self] in
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

private typealias IBActions = ShaderPaintViewController
extension IBActions {
    @IBAction func hideTutorialAction(_ sender: Any) {
        stateMachine.tutorialFinished()
    }
    
    @IBAction func homeTapped(_ sender: Any) {
        delegate?.dismiss(self)
    }
    
    @IBAction func saveImageTapped(_ sender: Any) {
        guard let photo = arController?.savePhoto() else { return }
        Bugsnag.leaveBreadcrumb(withMessage: "Shader: saved photo")
        trackEvent(name: "saved photo", parameters: nil)
        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        userHint.enqueueMessage(message: "Photo saved to album", duration: 2)
    }
    
    @IBAction func resetTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Shader: reset")
        trackEvent(name: "reset scene", parameters: nil)
        stateMachine.reset()
    }
    
    @IBAction func occlusionWizardTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Shader: show occlusion wizard")
        delegate?.showOcclusionWizard(self)
    }
    
    @IBAction func cartTapped(_ sender: Any) {
        Bugsnag.leaveBreadcrumb(withMessage: "Shader: show cart")
        trackEvent(name: "show cart", parameters: nil)
        guard let paint = currentPaint
        else { return }
        
        let wallInfo = WallInfo(
            id: "",
            area: AreaInfo(width: 0, height: 0),
            paint: WallPaint(id: paint.id, name: paint.name, color: paint.color),
            surfaceType: .wall,
            occlusionInfo: OcclusionInfo()
        )
        
        let paintInfo = PaintInfo(paintedWalls: [wallInfo],
                                  wallAreaByPaintId: [String: Double](),
                                  totalWallArea: 0,
                                  ceilingArea: 0,
                                  numberOfWallsPainted: 1,
                                  occlusionInfo: OcclusionInfo())
        
        arController?.pauseScene()
        delegate?.showCart(paintInfo: paintInfo, controller: self)
    }
}

private typealias Configuration = ShaderPaintViewController
extension Configuration {
    public func setPaints(paints: [Paint]) {
        self.paints = paints
    }
    
    private func configureAR() {
        arController?.setTouchMode(mode: .brightness)
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
                        self.trackScreen(name: "Shader Paint tutorial", parameters: nil)
                        
                    case .pickingColor:
                        self.trackScreen(name: "Shader Paint picking color", parameters: nil)
                        
                    case .fullUI:
                        self.trackEvent(name: "Shader Paint paint success", parameters: nil)
                    }
                }
                self.lastState = self.stateMachine.statePublisher
            }
            .store(in: &cancellables)
    }
    
    private func updateView(viewModel: ShaderPaintStateMachine.State) {
        paintSuccess = viewModel.paintSuccess
        tutorialView.isHidden = !viewModel.tutorialVisible
        uiControls.isHidden = !viewModel.uiControlsVisible
        cartButton.isHidden = !viewModel.cartButtonVisible
        colorPicker?.isHidden = !viewModel.colorPickerVisible
        
        if let hint = viewModel.userHint(color: hintColor,
                                         font: hintFont,
                                         icon: hintIcon) {
            userHint.isHidden = false
            userHint.clearQueue()
            userHint.enqueueMessage(
                message: .attributedString(message: hint, duration: 6)
            )
        } else {
            userHint.isHidden = true
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
        createARView()
        configureBindings()
        arController?.startScene(reset: true)
        colorPicker?.reloadPicker()
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
        
        arController = RemodelARLib.makeShaderARController(with: arscnView)
    }
    
    private func configureBindings() {
        arController?.retrievedWallColorSample = { [weak self] color in
            guard let self = self else { return }

            self.delegate?.retrievedWallColorSample(color: color, controller: self)
        }
//        arController?.analyticsTracking = { event in
//            print("event: \(event.analyticsData.event)")
//        }
    }
    
    private func applyUICustomization() {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let resetIcon = uiOptions.buttonIcons.resetSceneIcon
        let saveImageIcon = uiOptions.buttonIcons.saveImageIcon
        let occlusionsIcon = uiOptions.buttonIcons.shaderOcclusionsIcon
        let homeIcon = uiOptions.buttonIcons.homeIcon
        let cartIcon = uiOptions.buttonIcons.shoppingCartIcon
        
        sceneResetButton.imageView.setImage(with: resetIcon, placeholder: nil)
        shaderOcclusionsButton.imageView.setImage(with: occlusionsIcon, placeholder: nil)
        saveImageButton.imageView.setImage(with: saveImageIcon, placeholder: nil)
        homeButton.imageView.setImage(with: homeIcon, placeholder: nil)
        cartButton.imageView.setImage(with: cartIcon, placeholder: nil)
        
        let primaryFont = uiOptions.font.font(with: 16)
        let secondaryFont = uiOptions.font.font(with: 16)
        colorPicker?.configurePrimaryTitleLabelStyle(primaryFont, textColor)
        colorPicker?.configureSecondaryTitleLabelStyle(secondaryFont, textColor)
        
        hintFont = uiOptions.font.font(with: 16)
        hintColor = textColor
        hintIcon = nil
        userHint.setFont(font: hintFont, color: hintColor)
        
        tutorialTitle.textColor = textColor
        tutorialContent.textColor = textColor
        tutorialOkButton.setTitleColor(textColor, for: .normal)
        tutorialTitle.font = uiOptions.font.font(with: 18)
        tutorialContent.font = uiOptions.font.font(with: 14)
        tutorialOkButton.titleLabel?.font = uiOptions.font.font(with: 14)
        
        if let occlusionIconImage = occlusionsIcon.1 {
            hintIcon = occlusionIconImage
        } else {
            occlusionsIcon.0?.resource?.downloadImage(completion: { [weak self] image in
                self?.hintIcon = image
            })
        }
    }
}

private typealias Gestures = ShaderPaintViewController
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

private typealias PaintPickerData = ShaderPaintViewController
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

private typealias PaintPickerDelegateCallbacks = ShaderPaintViewController
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

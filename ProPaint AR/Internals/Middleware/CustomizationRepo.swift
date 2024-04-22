//
//  CustomizationRepo.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/21/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import AudioToolbox
import Foundation
import Kingfisher
import PromiseKit
import RemodelAR
import UIKit

protocol CustomizationRepo {
    var options: CustomizationOptions { get }
    
    func prefetchImages(progress: ((Float) -> Void)?, done: (() -> Void)?)
}

class CustomizationRepoImpl: CustomizationRepo {
    private let optionsAPI: OptionsAPI
    private let storeId: String
    private var lastUpdatedColors: Date?
    var options = CustomizationOptions.empty()
        
    init(optionsAPI: OptionsAPI, storeId: String) {
        self.optionsAPI = optionsAPI
        self.storeId = storeId
    }
    
    func prefetchImages() -> Promise<Void> {
        let promise = Promise<Void> { seal in
            optionsAPI.fetchOptions(storeId: storeId) { [weak self] options, error in
                if error != nil {
                    return
                }
                self?.options = options
                seal.fulfill(())
            }
        }
        
        return promise.then {
            self.options.prefetchImages()
        }
    }
    
    func prefetchImages(
        progress: ((Float) -> Void)?,
        done: (() -> Void)?
    ) {
        optionsAPI.fetchOptions(storeId: storeId) { [weak self] options, error in
            if error != nil {
                return
            }
            self?.options = options
            
            let sources = options.prefetchImageSources()
            ImagePrefetcher(resources: sources, options: nil) { _, _, completed in
                let completed = completed.count
                progress?(Float(completed) / Float(sources.count))
            } completionHandler: { _, _, _ in
                done?()
            }.start()
        }
    }
}

struct CustomizationOptions: Codable {
    let uiOptions: UIOptions
    let arOptions: ArOptions

    public func prefetchImages() -> Promise<Void> {
        firstly {
            uiOptions.prefetchImages()
        }.then {
            arOptions.prefetchImages()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        var allResources = uiOptions.prefetchImageSources()
        allResources.append(contentsOf: arOptions.prefetchImageSources())
        return allResources
    }
    
    enum CodingKeys: String, CodingKey {
        case uiOptions = "ui_options"
        case arOptions = "ar_options"
    }
    
    static func empty() -> CustomizationOptions {
        CustomizationOptions(uiOptions: .empty(),
                             arOptions: .empty())
    }
}

// MARK: - ArOptions
struct ArOptions: Codable {
    let gridImageUrl: RenderableImage
    let lidar: Lidar
    let floorplan: Floorplan
    let legacy: Legacy
    let roomplan: RoomPlan

    var gridImage: (ImageData?, UIImage?) {
        gridImageUrl.imageData(key: CodingKeys.gridImageUrl.rawValue)
    }
    
    var allImages: [(ImageData?, UIImage?)] {
        [
            gridImage
        ]
    }

    public func prefetchImages() -> Promise<Void> {
        let promise = Promise<Void> { seal in
            let allResources = allImages.compactMap({ $0.0?.resource })
            ImagePrefetcher(resources: allResources, completionHandler: { _, _, _ in
                seal.fulfill(())
            }).start()
        }
        return promise.then {
            legacy.prefetchImages()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        var allResources = allImages.compactMap({ $0.0?.resource })
        allResources.append(contentsOf: legacy.prefetchImageSources())
        return allResources
    }
    
    enum CodingKeys: String, CodingKey {
        case gridImageUrl = "grid_image"
        case lidar, floorplan, legacy, roomplan
    }
    
    static func empty() -> Self {
        ArOptions(gridImageUrl: .empty(),
                  lidar: .empty(),
                  floorplan: .empty(),
                  legacy: .empty(),
                  roomplan: .empty())
    }
}

// MARK: - Floorplan
struct Floorplan: Codable {
    let selectedColorHex: String
    let unselectedColorHex: String
    let unpaintedWallColorHex: String
    let unpaintedWallBrightness: Float

    var selectedColor: UIColor {
        UIColor(hex: selectedColorHex)
    }
    
    var unselectedColor: UIColor {
        UIColor(hex: unselectedColorHex)
    }
    
    var unpaintedWallColor: UIColor {
        UIColor(hex: unpaintedWallColorHex)
    }
    
    enum CodingKeys: String, CodingKey {
        case selectedColorHex = "selected_color"
        case unselectedColorHex = "unselected_color"
        case unpaintedWallColorHex = "unpainted_wall_color"
        case unpaintedWallBrightness = "unpainted_wall_brightness"
    }
    
    static func empty() -> Self {
        Floorplan(selectedColorHex: .empty,
                  unselectedColorHex: .empty,
                  unpaintedWallColorHex: .empty,
                  unpaintedWallBrightness: -0.1)
    }
}

// MARK: - Legacy
struct Legacy: Codable {
    let centerDotUrl: RenderableImage
    let centerDotOuterUrl: RenderableImage
    let cornerImages: CornerImages
    
    var centerDot: (ImageData?, UIImage?) {
        centerDotUrl.imageData(key: CodingKeys.centerDotOuterUrl.rawValue)
    }
    
    var centerDotOuter: (ImageData?, UIImage?) {
        centerDotOuterUrl.imageData(key: CodingKeys.centerDotOuterUrl.rawValue)
    }
    
    var allImages: [(ImageData?, UIImage?)] {
        [
            centerDot
        ]
    }
    
    public func prefetchImages() -> Promise<Void> {
        let promise = Promise<Void> { seal in
            let allResources = allImages.compactMap({ $0.0?.resource })
            ImagePrefetcher(resources: allResources, completionHandler: { _, _, _ in
                seal.fulfill(())
            }).start()
        }
        return promise.then {
            cornerImages.prefetchImages()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        var allResources = allImages.compactMap({ $0.0?.resource })
        allResources.append(contentsOf: cornerImages.prefetchImageSources())
        return allResources
    }

    enum CodingKeys: String, CodingKey {
        case centerDotUrl = "center_dot"
        case centerDotOuterUrl = "center_dot_outer"
        case cornerImages = "corner_images"
    }
    
    static func empty() -> Self {
        Legacy(centerDotUrl: .empty(),
               centerDotOuterUrl: .empty(),
               cornerImages: .empty())
    }
}

// MARK: - RoomPlan
struct RoomPlan: Codable {
    let selectedColorHex: String
    let unselectedColorHex: String
    let unpaintedWallColorHex: String
    let unpaintedWallBrightness: Float

    var selectedColor: UIColor {
        UIColor(hex: selectedColorHex)
    }
    
    var unselectedColor: UIColor {
        UIColor(hex: unselectedColorHex)
    }
    
    var unpaintedWallColor: UIColor {
        UIColor(hex: unpaintedWallColorHex)
    }
    
    enum CodingKeys: String, CodingKey {
        case selectedColorHex = "selected_color"
        case unselectedColorHex = "unselected_color"
        case unpaintedWallColorHex = "unpainted_wall_color"
        case unpaintedWallBrightness = "unpainted_wall_brightness"
    }
    
    static func empty() -> Self {
        RoomPlan(selectedColorHex: .empty,
                 unselectedColorHex: .empty,
                 unpaintedWallColorHex: .empty,
                 unpaintedWallBrightness: -0.1)
    }
}

// MARK: - CornerImages
struct CornerImages: Codable {
    let upperLeftUrl, upperRightUrl, lowerLeftUrl, lowerRightUrl: RenderableImage
    
    var upperLeft: (ImageData?, UIImage?) {
        upperLeftUrl.imageData(key: CodingKeys.upperLeftUrl.rawValue)
    }
    var upperRight: (ImageData?, UIImage?) {
        upperRightUrl.imageData(key: CodingKeys.upperRightUrl.rawValue)
    }
    var lowerLeft: (ImageData?, UIImage?) {
        lowerLeftUrl.imageData(key: CodingKeys.lowerLeftUrl.rawValue)
    }
    var lowerRight: (ImageData?, UIImage?) {
        lowerRightUrl.imageData(key: CodingKeys.lowerRightUrl.rawValue)
    }
    
    var allImages: [(ImageData?, UIImage?)] {
        [
            upperLeft,
            upperRight,
            lowerLeft,
            lowerRight
        ]
    }
    
    public func prefetchImages() -> Promise<Void> {
        Promise { seal in
            let allResources = allImages.compactMap({ $0.0?.resource })
            ImagePrefetcher(resources: allResources, completionHandler: { _, _, _ in
                seal.fulfill(())
            }).start()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        allImages.compactMap({ $0.0?.resource })
    }
    
    enum CodingKeys: String, CodingKey {
        case upperLeftUrl = "upper_left"
        case upperRightUrl = "upper_right"
        case lowerLeftUrl = "lower_left"
        case lowerRightUrl = "lower_right"
    }
    
    static func empty() -> CornerImages {
        CornerImages(upperLeftUrl: .empty(),
                     upperRightUrl: .empty(),
                     lowerLeftUrl: .empty(),
                     lowerRightUrl: .empty())
    }
}

// MARK: - Lidar
struct Lidar: Codable {
    let scanStyle: LidarScanningStyle
    let unscannedColorHex: String
    let selectedColorHex: String
    let unscannedBrightness: Float
    
    var unscannedColor: UIColor {
        guard !unscannedColorHex.isEmpty
        else {
            return .black
        }
        
        return UIColor(hex: unscannedColorHex)
    }
    
    var selectedColor: UIColor {
        guard !selectedColorHex.isEmpty
        else {
            return .green
        }
        
        return UIColor(hex: selectedColorHex)
    }
    
    enum CodingKeys: String, CodingKey {
        case scanStyle = "scan_style"
        case unscannedColorHex = "unscanned_color"
        case unscannedBrightness = "unscanned_brightness"
        case selectedColorHex = "selected_color"
    }
    
    static func empty() -> Self {
        Lidar(scanStyle: .highlight,
              unscannedColorHex: .empty,
              selectedColorHex: .empty,
              unscannedBrightness: -0.1)
    }
}

// MARK: - UIOptions
struct UIOptions: Codable {
    let backgroundImageUrl: RenderableImage
    let font: FontInfo
    let methodIcons: MethodIcons
    let buttonIcons: ButtonIcons
    let colors: Colors
    
    var backgroundImage: (ImageData?, UIImage?) {
        backgroundImageUrl.imageData(key: CodingKeys.backgroundImageUrl.rawValue)
    }
    
    var allImages: [(ImageData?, UIImage?)] {
        [
            backgroundImage
        ]
    }
    
    public func prefetchImages() -> Promise<Void> {
        let promise = Promise<Void> { seal in
            let allResources = allImages.compactMap({ $0.0?.resource })
            ImagePrefetcher(resources: allResources, completionHandler: { _, _, _ in
                seal.fulfill(())
            }).start()
        }
        return promise.then {
            methodIcons.prefetchImages()
        }.then {
            buttonIcons.prefetchImages()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        var allResources = allImages.compactMap({ $0.0?.resource })
        allResources.append(contentsOf: methodIcons.prefetchImageSources())
        allResources.append(contentsOf: buttonIcons.prefetchImageSources())
        return allResources
    }
    
    enum CodingKeys: String, CodingKey {
        case backgroundImageUrl = "background_image"
        case font = "font"
        case methodIcons = "method_icons"
        case buttonIcons = "button_icons"
        case colors = "colors"
    }
    
    static func empty() -> Self {
        UIOptions(backgroundImageUrl: .empty(),
                  font: .empty(),
                  methodIcons: .configDemoIcon(),
                  buttonIcons: .empty(),
                  colors: .empty())
    }
}

struct Colors: Codable {
    let button: VariableColor
    let buttonText: VariableColor
    let frameBackground: VariableColor
    let icon: VariableColor
    let iconBackground: VariableColor
    let overlayBackground: VariableColor
    let subframeBackground: VariableColor
    let text: VariableColor
    let highlighted: VariableColor
    let unhighlighted: VariableColor
    let backgroundImageOverlay: VariableColor
    
    enum CodingKeys: String, CodingKey {
        case button
        case buttonText = "button_text"
        case frameBackground = "frame_background"
        case icon
        case iconBackground = "icon_background"
        case overlayBackground = "overlay_background"
        case subframeBackground = "subframe_background"
        case text
        case highlighted
        case unhighlighted
        case backgroundImageOverlay = "background_image_overlay"
    }
    
    static func empty() -> Self {
        Colors(
            button: .empty(),
            buttonText: .empty(),
            frameBackground: .empty(),
            icon: .empty(),
            iconBackground: .empty(),
            overlayBackground: .empty(),
            subframeBackground: .empty(),
            text: .empty(),
            highlighted: .empty(),
            unhighlighted: .empty(),
            backgroundImageOverlay: .empty())
    }
}

struct VariableColor: Codable {
    let light, dark: ColorInfo
    
    var color: UIColor {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return dark.uiColor
        } else {
            return light.uiColor
        }
    }
        
    static func empty() -> Self {
        VariableColor(light: .empty(), dark: .empty())
    }
}

// MARK: - Dark
struct ColorInfo: Codable {
    let color: String
    let opacity: Double
    
    var uiColor: UIColor {
        UIColor(hex: color, alpha: opacity)
    }
    
    static func empty() -> Self {
        ColorInfo(color: .empty, opacity: 1)
    }
}

struct FontInfo: Codable {
    let family: String
    let sizeOffset: CGFloat
    
    func font(with size: CGFloat?) -> UIFont {
        let size = size ?? 16
        return UIFont(name: family, size: size + sizeOffset) ?? UIFont.systemFont(ofSize: size + sizeOffset)
    }
    
    enum CodingKeys: String, CodingKey {
        case family = "family"
        case sizeOffset = "size_offset"
    }
    
    static func empty() -> Self {
        FontInfo(family: "Helvetica-Neue", sizeOffset: 0)
    }
}

// MARK: - ButtonIcons
struct ButtonIcons: Codable {
    let hideFloorplanUnpaintedIconUrl,
        showFloorplanUnpaintedIconUrl,
        shaderOcclusionsIconUrl,
        shaderOcclusionColorTrashIconUrl,
        saveImageIconUrl,
        saveCartImageIconUrl: RenderableImage
    let resetSceneIconUrl,
        homeIconUrl,
        shoppingCartIconUrl,
        shaderOcclusionCloseIconUrl: RenderableImage
    let methodInfoBackButtonIconUrl,
        methodInfoIconUrl: RenderableImage
    let mlMethodIcons: MLMethodIcons

    var hideFloorplanUnpaintedIcon: (ImageData?, UIImage?) {
        hideFloorplanUnpaintedIconUrl.imageData(key: CodingKeys.hideFloorplanUnpaintedIconUrl.rawValue)
    }
    var showFloorplanUnpaintedIcon: (ImageData?, UIImage?) {
        showFloorplanUnpaintedIconUrl.imageData(key: CodingKeys.showFloorplanUnpaintedIconUrl.rawValue)
    }
    var shaderOcclusionsIcon: (ImageData?, UIImage?) {
        shaderOcclusionsIconUrl.imageData(key: CodingKeys.shaderOcclusionsIconUrl.rawValue)
    }
    var shaderOcclusionColorTrashIcon: (ImageData?, UIImage?) {
        shaderOcclusionColorTrashIconUrl.imageData(key: CodingKeys.shaderOcclusionColorTrashIconUrl.rawValue)
    }
    var saveImageIcon: (ImageData?, UIImage?) {
        saveImageIconUrl.imageData(key: CodingKeys.saveImageIconUrl.rawValue)
    }
    var saveCartImageIcon: (ImageData?, UIImage?) {
        saveCartImageIconUrl.imageData(key: CodingKeys.saveCartImageIconUrl.rawValue)
    }
    var resetSceneIcon: (ImageData?, UIImage?) {
        resetSceneIconUrl.imageData(key: CodingKeys.resetSceneIconUrl.rawValue)
    }
    var homeIcon: (ImageData?, UIImage?) {
        homeIconUrl.imageData(key: CodingKeys.homeIconUrl.rawValue)
    }
    var shoppingCartIcon: (ImageData?, UIImage?) {
        shoppingCartIconUrl.imageData(key: CodingKeys.shoppingCartIconUrl.rawValue)
    }
    var shaderOcclusionCloseIcon: (ImageData?, UIImage?) {
        shaderOcclusionCloseIconUrl.imageData(key: CodingKeys.shaderOcclusionCloseIconUrl.rawValue)
    }
    var methodInfoBackButtonIcon: (ImageData?, UIImage?) {
        methodInfoBackButtonIconUrl.imageData(key: CodingKeys.methodInfoBackButtonIconUrl.rawValue)
    }
    var methodInfoIcon: (ImageData?, UIImage?) {
        methodInfoIconUrl.imageData(key: CodingKeys.methodInfoIconUrl.rawValue)
    }
    
    var allImages: [(ImageData?, UIImage?)] {
        [
            hideFloorplanUnpaintedIcon,
            showFloorplanUnpaintedIcon,
            shaderOcclusionsIcon,
            shaderOcclusionColorTrashIcon,
            saveImageIcon,
            resetSceneIcon,
            homeIcon,
            shoppingCartIcon,
            shaderOcclusionCloseIcon,
            methodInfoBackButtonIcon,
            methodInfoIcon
        ]
    }
    
    public func prefetchImages() -> Promise<Void> {
        let promise = Promise<Void> { seal in
            let allResources = allImages.compactMap({ $0.0?.resource })
            ImagePrefetcher(resources: allResources, completionHandler: { _, _, _ in
                seal.fulfill(())
            }).start()
        }
        return promise.then {
            mlMethodIcons.prefetchImages()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        var allResources = allImages.compactMap({ $0.0?.resource })
        allResources.append(contentsOf: mlMethodIcons.prefetchImageSources())
        return allResources
    }
    
    enum CodingKeys: String, CodingKey {
        case hideFloorplanUnpaintedIconUrl = "hide_floorplan_unpainted_icon"
        case showFloorplanUnpaintedIconUrl = "show_floorplan_unpainted_icon"
        case shaderOcclusionsIconUrl = "shader_occlusions_icon"
        case shaderOcclusionColorTrashIconUrl = "shader_occlusion_color_trash_icon"
        case saveImageIconUrl = "save_image_icon"
        case saveCartImageIconUrl = "save_cart_image_icon"
        case resetSceneIconUrl = "reset_scene_icon"
        case homeIconUrl = "home_icon"
        case shoppingCartIconUrl = "shopping_cart_icon"
        case shaderOcclusionCloseIconUrl = "shader_occlusion_close_icon"
        case methodInfoBackButtonIconUrl = "method_info_back_button_icon"
        case methodInfoIconUrl = "method_info_icon"
        case mlMethodIcons = "ML_Method_icons"
    }
    
    static func empty() -> Self {
        ButtonIcons(hideFloorplanUnpaintedIconUrl: .empty(),
                    showFloorplanUnpaintedIconUrl: .empty(),
                    shaderOcclusionsIconUrl: .empty(),
                    shaderOcclusionColorTrashIconUrl: .empty(),
                    saveImageIconUrl: .empty(),
                    saveCartImageIconUrl: .empty(),
                    resetSceneIconUrl: .empty(),
                    homeIconUrl: .empty(),
                    shoppingCartIconUrl: .empty(),
                    shaderOcclusionCloseIconUrl: .empty(),
                    methodInfoBackButtonIconUrl: .empty(),
                    methodInfoIconUrl: .empty(),
                    mlMethodIcons: .empty())
    }
}

// MARK: - MethodIcons
struct MethodIcons: Codable {
    let lidarIconUrl, floorplanIconUrl, legacyIconUrl, shaderIconUrl, mlsdkIconUrl: RenderableImage
    
    var lidarIcon: (ImageData?, UIImage?) {
        lidarIconUrl.imageData(key: CodingKeys.lidarIconUrl.rawValue)
    }
    
    var floorplanIcon: (ImageData?, UIImage?) {
        floorplanIconUrl.imageData(key: CodingKeys.floorplanIconUrl.rawValue)
    }
    
    var legacyIcon: (ImageData?, UIImage?) {
        legacyIconUrl.imageData(key: CodingKeys.legacyIconUrl.rawValue)
    }
    
    var shaderIcon: (ImageData?, UIImage?) {
        shaderIconUrl.imageData(key: CodingKeys.shaderIconUrl.rawValue)
    }
    
    var mlsdkIcon: (ImageData?, UIImage?) {
        mlsdkIconUrl.imageData(key: CodingKeys.mlsdkIconUrl.rawValue)
    }
    
    var allImages: [(ImageData?, UIImage?)] {
        [
            lidarIcon,
            floorplanIcon,
            legacyIcon,
            shaderIcon,
            mlsdkIcon
        ]
    }

    public func prefetchImages() -> Promise<Void> {
        Promise { seal in
            let allResources = allImages.compactMap({ $0.0?.resource })
            ImagePrefetcher(resources: allResources, completionHandler: { _, _, _ in
                seal.fulfill(())
            }).start()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        allImages.compactMap({ $0.0?.resource })
    }
    
    enum CodingKeys: String, CodingKey {
        case lidarIconUrl = "lidar_icon"
        case floorplanIconUrl = "floorplan_icon"
        case legacyIconUrl = "legacy_icon"
        case shaderIconUrl = "shader_icon"
        case mlsdkIconUrl = "mlsdk_icon"
    }
    
    static func configDemoIcon() -> Self {
        MethodIcons(
            lidarIconUrl: RenderableImage(url: .empty,
                                          tintColor: nil,
                                          systemIcon: nil),
            floorplanIconUrl: RenderableImage(url: .empty,
                                              tintColor: nil,
                                              systemIcon: nil),
            legacyIconUrl: RenderableImage(url: .empty,
                                           tintColor: nil,
                                           systemIcon: nil),
            shaderIconUrl: RenderableImage(url: .empty,
                                           tintColor: nil,
                                           systemIcon: nil),
            mlsdkIconUrl: RenderableImage(url: .empty,
                                          tintColor: nil,
                                          systemIcon: nil)
        )
    }
}

struct MLMethodIcons: Codable {
    let environmentIconUrl,
        surfaceIconUrl,
        abnormalityIconUrl: RenderableImage

    var environmentIcon: (ImageData?, UIImage?) {
        environmentIconUrl.imageData(key: CodingKeys.environmentIconUrl.rawValue)
    }
    
    var surfaceIcon: (ImageData?, UIImage?) {
        surfaceIconUrl.imageData(key: CodingKeys.surfaceIconUrl.rawValue)
    }
    
    var abnormalityIcon: (ImageData?, UIImage?) {
        abnormalityIconUrl.imageData(key: CodingKeys.abnormalityIconUrl.rawValue)
    }

    var allImages: [(ImageData?, UIImage?)] {
        [
            environmentIcon,
            surfaceIcon,
            abnormalityIcon
        ]
    }
    
    public func prefetchImages() -> Promise<Void> {
        Promise { seal in
            let allResources = allImages.compactMap({ $0.0?.resource })
            ImagePrefetcher(resources: allResources, completionHandler: { _, _, _ in
                seal.fulfill(())
            }).start()
        }
    }
    
    public func prefetchImageSources() -> [Resource] {
        allImages.compactMap({ $0.0?.resource })
    }
    
    enum CodingKeys: String, CodingKey {
        case environmentIconUrl = "environment_icon"
        case surfaceIconUrl = "surface_icon"
        case abnormalityIconUrl = "abnormality_icon"
    }
    
    static func configDemoIcon() -> Self {
        MLMethodIcons(
            environmentIconUrl: RenderableImage(url: "environment",
                                                tintColor: nil,
                                                systemIcon: nil),
            surfaceIconUrl: RenderableImage(url: "surface",
                                            tintColor: nil,
                                            systemIcon: nil),
            abnormalityIconUrl: RenderableImage(url: "abnormality",
                                                tintColor: nil,
                                                systemIcon: nil)
        )
    }
    
    static func empty() -> Self {
        MLMethodIcons(environmentIconUrl: .empty(),
                      surfaceIconUrl: .empty(),
                      abnormalityIconUrl: .empty())
    }
}

public struct ImageData {
    var resource: Resource?
    var placeholder: UIImage?
    let tintColor: UIColor?
    
    public init(key: String, url: String?, tintColor: UIColor?) {
        placeholder = UIImage(named: key)
        resource = nil
        self.tintColor = tintColor
        if let safeUrlString = url,
            let resourceUrl = URL(string: safeUrlString) {
            resource = KF.ImageResource(downloadURL: resourceUrl, cacheKey: key)
        }
    }
    
    static func empty() -> Self {
        ImageData(key: .empty, url: .empty, tintColor: nil)
    }
}

struct RenderableImage: Codable {
    let url: String
    let tintColor: String?
    let systemIcon: String?
    
    var systemImage: UIImage? {
        guard let systemIcon = systemIcon,
              !systemIcon.isEmpty
        else { return nil }

        if let tintColor = tintColor {
            let tint = UIColor(hex: tintColor)
            return UIImage(systemName: systemIcon)?
                .withTintColor(tint, renderingMode: .alwaysTemplate)
        }
        
        return UIImage(systemName: systemIcon)
    }
    
    func imageData(key: String) -> (ImageData?, UIImage?) {
        var customTintColor: UIColor?
        if let tintColor = tintColor,
           !tintColor.isEmpty {
            customTintColor = UIColor(hex: tintColor)
        }
        
        if let systemImage = systemImage {
            return (ImageData(key: key, url: "", tintColor: customTintColor), systemImage)
        }
        
        if !url.isEmpty {
            return (ImageData(key: key, url: url, tintColor: customTintColor), nil)
        }
        return (nil, nil)
    }
    
    static func empty() -> Self {
        RenderableImage(url: .empty, tintColor: nil, systemIcon: nil)
    }
}

extension Resource {
    func downloadImage(completion: @escaping (UIImage?) -> Void) {
        KingfisherManager.shared.retrieveImage(with: self, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                completion(value.image)
                
            case .failure:
                completion(nil)
            }
        }
    }
    
    func downloadImage() -> Promise<UIImage?> {
        Promise<UIImage?> { seal in
            KingfisherManager.shared.retrieveImage(with: self, options: nil, progressBlock: nil) { result in
                switch result {
                case .success(let value):
                    seal.fulfill(value.image)
                    
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

extension Dictionary where Key == Corners, Value == Resource {
    func downloadImages() -> Promise<[Corners: UIImage]> {
        Promise<[Corners: UIImage]> { seal in
        let promises = map { element in
            Promise<(Corners, UIImage)> { seal in
                KingfisherManager.shared.retrieveImage(with: element.value,
                                                       options: nil, progressBlock: nil) { result in
                    switch result {
                    case .success(let value):
                        seal.fulfill((element.key, value.image))

                    case .failure(let error):
                        seal.reject(error)
                    }
                }
            }
        }
        
        when(fulfilled: promises)
            .done { results in
                var output = [Corners: UIImage]()
                for result in results {
                    output[result.0] = result.1
                }
                seal.fulfill(output)
            }
            .catch { error in
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

public enum LidarScanningStyle: String, Codable {
    case mesh
    case highlight
    
    var rawInt: Int {
        switch self {
        case .mesh:
            return 0
            
        case .highlight:
            return 1
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case environmentIconUrl = "environment_icon"
        case surfaceIconUrl = "surface_icon"
        case abnormalityIconUrl = "abnormality_icon"
    }
}

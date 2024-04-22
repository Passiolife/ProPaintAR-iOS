//
//  AnalyticsConfiguration+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import RemodelAR

extension AnalyticsConfiguration {
    static var appConfiguration: AnalyticsConfiguration {
        var standard = AnalyticsConfigurationStandard()
        standard.pauseScene = false
        standard.resetScene = false
        standard.save3DModel = true
        standard.savePhoto = true
        standard.retrievePaintInfo = true
        standard.retrieveRawCameraImage = false
        standard.setLidarScanStyle = false
        standard.setRenderMode = false
        standard.startScene = true
        
        var materials = AnalyticsConfigurationMaterials()
        materials.setBrightness = true
        materials.setColor = false
        materials.setTexture = false
        materials.clearColor = false
        materials.clearTexture = false
        materials.setColorThreshold = true
        materials.setOcclusionColors = true
        
        var legacy = AnalyticsConfigurationLegacy()
        legacy.placeWallBasePlane = true
        legacy.setFirstCorner = true
        legacy.setSecondCorner = true
        legacy.cancelAddWall = true
        legacy.setTouchMode = false
        legacy.updateWallBasePlane = false
        
        var floorplan = AnalyticsConfigurationFloorplan()
        floorplan.removeLastCorner = true
        floorplan.finishCorners = true
        floorplan.finishHeight = true
        floorplan.showUnpaintedWalls = true
        
        var uiCustomization = AnalyticsConfigurationUICustomization()
        uiCustomization.enableBrightnessDragAdjustment = false
        uiCustomization.enableBrightnessTapAdjustment = false
        uiCustomization.setDeselectedColor = false
        uiCustomization.setGridImage = false
        uiCustomization.setLegacyUIImages = false
        uiCustomization.setMeshColor = false
        uiCustomization.setSelectedColor = false
        uiCustomization.setUnpaintedColor = false
        
        var touch = AnalyticsConfigurationTouch()
        touch.handleTouch = false
        touch.dragStart = false
        touch.dragEnd = false
        
        let config = AnalyticsConfiguration(
            standard: standard,
            materials: materials,
            legacy: legacy,
            floorplan: floorplan,
            uiCustomization: uiCustomization,
            touch: touch
        )
        
        return config
    }
}

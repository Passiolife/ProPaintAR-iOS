//
//  ARMethodInfo.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//
// swiftlint:disable line_length

import ARKit
import Foundation

struct ARMethod {
    let type: ARType
    let description: String
    let iconName: String
    let info: ARMethodInfo
}

extension ARMethod {
    static var data: [ARMethod] {
        let roomplan = ARMethod(
            type: .roomplan,
            description: "Scan walls and create a floorplan automatically using the device Lidar sensor",
            iconName: "RoomPlan",
            info: ARMethodInfo(arType: .roomplan,
                               description: "RoomPlan uses the sensors on your device to automatically generate an accurate floorplan of your space which can be used to visualize paint colors on your walls.",
                               imageLeft: "RoomPlanInfo1",
                               imageTitleLeft: "Scan",
                               imageRight: "RoomPlanInfo2",
                               imageTitleRight: "Preview/Export")
        )
        let lidar = ARMethod(
            type: .lidar,
            description: "Scan walls and create geometry using the device Lidar sensor",
            iconName: "lidar",
            info: ARMethodInfo(arType: .lidar,
                               description: "Live Paint uses the sensors on your device to generate geometry that is used to visualize paint colors on your walls. This approach automatically gives you basic object occlusion, meaning foreground objects won’t be painted, resulting in a more realistic paint visualization experience.",
                               imageLeft: "lidarInfo1",
                               imageTitleLeft: "Meshed Room",
                               imageRight: "lidarInfo2",
                               imageTitleRight: "Painted Mesh")
        )
        let floorplan = ARMethod(
            type: .floorplan,
            description: "Select the corners of your rooms floor to create a full room experience",
            iconName: "floorplan",
            info: ARMethodInfo(arType: .floorplan,
                               description: "Floorplan allows selecting each corner of the room to be painted, creating a virtual copy of the floorplan. The user then drags to set the room height. The resulting geometry allows the user to visualize products on walls, floors, and ceilings. Combined with Shader based occlusions, foreground objects can be removed from the paint visualization.",
                               imageLeft: "floorplanInfo1",
                               imageTitleLeft: "Placing Corners",
                               imageRight: "floorplanInfo2",
                               imageTitleRight: "Setting Height")
        )
        let swatch = ARMethod(
            type: .swatch,
            description: "Manually place a wall patch by selecting points on a wall",
            iconName: "legacy",
            info: ARMethodInfo(arType: .swatch,
                               description: "Area Paint creates geometry on walls using the users device to orient the wall patches. This approach gives you the advantage of allowing users to manually determine where they want to visualize paint. Combined with Shader based occlusions, foreground objects can be removed from the paint visualization.",
                               imageLeft: "legacyInfo1",
                               imageTitleLeft: "Mesh Placement",
                               imageRight: "legacyInfo2",
                               imageTitleRight: "Placed Patch")
        )
        let shader = ARMethod(
            type: .shader,
            description: "Select colors from your wall to choose which surfaces paint will be visualized on",
            iconName: "colorRange",
            info: ARMethodInfo(arType: .shader,
                               description: "Color Range allows users to visualize paint without using AR. This approach uses up to three selected wall colors from the target wall to only paint parts of the wall that are close in color to the group of selected colors. This approach doesn’t work for every situation, but works well when it does.",
                               imageLeft: "shaderInfo1",
                               imageTitleLeft: "Unpainted",
                               imageRight: "shaderInfo2",
                               imageTitleRight: "Painted")
        )
        let mlsdk = ARMethod(
            type: .mlsdk,
            description: "Use our proprietary machine learning SDK to recognize your environments",
            iconName: "sdk",
            info: ARMethodInfo(arType: .mlsdk,
                               description: "Environment Recognition (using the Passio Remodel-AI SDK) enables the identification of environments, surface types, and defects to enhance the user experience of your app. The SDK doesn’t require an internet connection to give immediate and accurate results.",
                               imageLeft: nil,
                               imageTitleLeft: nil,
                               imageRight: nil,
                               imageTitleRight: nil)
        )
        var methods = [ARMethod]()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            if #available(iOS 16, *) {
                methods.append(roomplan)
            }
            methods.append(lidar)
        }
        if ARConfiguration.isSupported {
            methods.append(floorplan)
            methods.append(swatch)
            methods.append(shader)
        }
        methods.append(mlsdk)
        return methods
    }
}

struct ARMethodInfo {
    let arType: ARType
    let description: String
    let imageLeft: String?
    let imageTitleLeft: String?
    let imageRight: String?
    let imageTitleRight: String?
}

enum ARType: String {
    case roomplan = "Room Plan"
    case lidar = "Live Paint"
    case swatch = "Area Paint"
    case floorplan = "Floorplan"
    case shader = "Color Range"
    case mlsdk = "Environment Recognition"
}

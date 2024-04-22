//
//  MLManager.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 2/27/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
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

class MLManager: NSObject {
    private let passioSDK = PassioRemodelAI.shared
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let parentView: UIView
    private let cropView: UIView
    private var isPhoneStill = false
    private var isProcessingImage = false
    private var lastImageTime = Date()
    private var cropType: CropType = .cropped
    private var activeModelType: ModelType = .environments
    private var targetUpdateInterval = 0.2
    private var rollingUpdateInterval = 5
    private var rollingUpdateCount = 0
    private var rollingAverageCount = 50
    private var rollingAverageTime: Double = 2.5
    private var rollingCandidates = [ClassificationCandidateImp]()
    private var rollingStart = CFAbsoluteTimeGetCurrent()
    private var debugLines = [String]() {
        didSet {
            debugLinesUpdated?(debugLines)
        }
    }
    
    var debugLinesUpdated: (([String]) -> Void)?
    var scanSuccess: ((MLDisplayModel) -> Void)?
    
    init(parentView: UIView, cropView: UIView) {
        self.parentView = parentView
        self.cropView = cropView
    }
    
    func teardown() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        videoOutput?.setSampleBufferDelegate(nil, queue: DispatchQueue(label: "videoQueue"))
    }
    
    func setPhoneMotion(isPhoneStill: Bool) {
        self.isPhoneStill = isPhoneStill
    }
    
    func setCropType(cropType: CropType) {
        self.cropType = cropType
    }
    
    func setModelType(modelType: ModelType) {
        self.activeModelType = modelType
    }
    
    private func attemptGetNormalCamera() -> AVCaptureDevice? {
        let videoSession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInDualCamera
            ],
            mediaType: .video,
            position: .back
        )
        
        return videoSession.devices.first
    }
    
    private func attemptGetWideCamera() -> AVCaptureDevice? {
        let videoSession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInDualWideCamera
            ],
            mediaType: .video,
            position: .back
        )
        
        return videoSession.devices.first
    }
    
    func setupPreviewLayer() {
        captureSession = AVCaptureSession()
        guard let session = captureSession else { return }
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080
        
        let wideDevice = attemptGetWideCamera()
        let normalDevice = attemptGetNormalCamera()
        var device: AVCaptureDevice?
        var zoomFactor: Float = 1
        if wideDevice != nil {
            device = wideDevice
            zoomFactor = 2
        } else {
            device = normalDevice
        }
        
        guard let videoDevice = device,
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput)
        else { return }
        
        session.addInput(videoDeviceInput)
        let videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput = videoOutput
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        guard session.canAddOutput(videoOutput) else { return }
        
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.videoZoomFactor = CGFloat(zoomFactor)
            videoDevice.unlockForConfiguration()
        } catch {
            print("Error: \(error)")
        }
        
        session.addOutput(videoOutput)
        session.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer()
        
        guard let preview = previewLayer else { return }
        
        preview.backgroundColor = UIColor.black.cgColor
        preview.session = captureSession
        
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
        
        preview.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview.frame = parentView.bounds
        preview.connection?.videoOrientation = .portrait
        parentView.layer.insertSublayer(preview, at: 0)
    }
    
    private func addScanResult(result: ClassificationCandidateImp) {
        rollingUpdateCount += 1
        rollingCandidates.append(result)
        while rollingCandidates.count > rollingAverageCount {
            rollingCandidates.remove(at: 0)
        }
    }
    
    private func updateScanResult() {
        var classCounts = [String: TimeSeriesConfidenceCount]()
        for (index, candidate) in rollingCandidates.enumerated() {
            let confidence = candidate.confidence
            if let data = classCounts[candidate.passioID] {
                let maxConfidence = max(confidence, data.maxConfidence)
                classCounts[candidate.passioID] = TimeSeriesConfidenceCount(
                    confidenceData: data,
                    confidence: confidence,
                    maxIndex: index,
                    maxConfidence: maxConfidence
                )
            } else {
                classCounts[candidate.passioID] = TimeSeriesConfidenceCount(
                    candidate: candidate,
                    confidence: confidence,
                    maxIndex: index,
                    maxConfidence: confidence
                )
            }
        }
        
        let allResults = classCounts
            .values
            .sorted(by: { $0.totalConfidence > $1.totalConfidence })
        
        let mostSeen = classCounts
            .compactMap({ $0.value })
            .max(by: { $0.totalConfidence < $1.totalConfidence })
        if let candidate = mostSeen?.candidate,
           let dic = passioIDDic[candidate.passioID],
           let description = dic["en"] {
            let object = MLDisplayModel(objectID: candidate.passioID,
                                        description: description,
                                        confidence: mostSeen?.totalConfidence ?? candidate.confidence,
                                        boundingBox: nil,
                                        allResults: allResults)
            self.scanSuccess?(object)
            self.debugLines = object.debugLines
        }
    }
}

extension MLManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard var image = sampleBuffer.image(orientation: .portrait),
              isPhoneStill,
              !isProcessingImage
        else { return }
        
        isProcessingImage = true
        lastImageTime = Date()
        
        if activeModelType == .abnormalities {
            switch cropType {
            case .full:
                detectObjects(image: image) { [weak self] in
                    self?.isProcessingImage = false
                }
                
            case .cropped:
                DispatchQueue.main.async { [weak self] in
                    guard let self = self
                    else { return }
                    
                    image = self.cropImage(image: image)
                    self.detectObjects(image: image) {
                        self.isProcessingImage = false
                    }
                }
                
            case .fullAndCropped:
                DispatchQueue.main.async { [weak self] in
                    guard let self = self
                    else { return }
                    
                    let croppedImage = self.cropImage(image: image)
                    self.detectObjects(image: image) {
                        self.detectObjects(image: croppedImage) {
                            self.isProcessingImage = false
                        }
                    }
                }
            }
        } else {
            detectObjects(image: image) { [weak self] in
                self?.isProcessingImage = false
            }
        }
    }
    
    private func cropImage(image: UIImage) -> UIImage {
        let screenSize = parentView.bounds.size
        let size = cropView.bounds.size
        let imageCropWidth = image.size.height * screenSize.width / screenSize.height
        let imageOverlap = (image.size.width - imageCropWidth) / 2
        let origin = self.parentView.convert(cropView.bounds.origin, from: cropView)
        let cropWidth = size.width / screenSize.width * imageCropWidth
        let cropX = origin.x / screenSize.width * imageCropWidth + imageOverlap
        let cropY = (image.size.height - cropWidth) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropWidth)
        return image.crop(rect: cropRect) ?? image
    }
    
    private func detectObjects(image: UIImage, callback: @escaping () -> Void) {
        if #available(iOS 15.0, *),
           MLCDevice.ane() != nil {
            passioSDK.mlComputeUnits = .all
        }
        
        passioSDK.detectCustomPassioIDIn(
            image: image,
            modelName: activeModelType.name
        ) { [weak self] _, candidates in
            guard let self = self,
                  let candidates = candidates
            else {
                callback()
                return
            }
            
            let filtered = candidates
//                .filter({ $0.passioID != "BKG0001" })
                .sorted(by: { $0.confidence > $1.confidence })
            
            if let first = filtered.first {
                self.addScanResult(result: first.toClassDetectionImp())
                if self.rollingUpdateCount >= self.rollingUpdateInterval {
                    let duration = CFAbsoluteTimeGetCurrent() - self.rollingStart
                    if duration < self.targetUpdateInterval {
                        self.rollingUpdateInterval += 1
                    } else if duration > self.targetUpdateInterval {
                        self.rollingUpdateInterval -= 1
                    }
                    let processTime = duration / Double(self.rollingUpdateCount)
                    self.rollingAverageCount = Int(self.rollingAverageTime / processTime)
                    self.rollingUpdateCount = 0
                    self.rollingStart = CFAbsoluteTimeGetCurrent()
                    self.updateScanResult()
                }
            }
            callback()
        }
    }
    
    private func transformCGRectToPreviewLayer(boundingBox: CGRect) -> CGRect {
        let width = parentView.bounds.width
        let height = parentView.bounds.height
        let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height)
        var rectTransform = boundingBox.applying(scale).applying(transform)
        let spaceFromTop: CGFloat = 0.0
        if rectTransform.origin.y < spaceFromTop {
            rectTransform = CGRect(x: rectTransform.origin.x,
                                   y: spaceFromTop,
                                   width: rectTransform.width,
                                   height: rectTransform.height - spaceFromTop)
        }
        return rectTransform
    }
}

struct TimeSeriesConfidenceCount {
    let candidate: ClassificationCandidateImp
    let sampleCount: Int
    let confidence: Double
    let maxIndex: Int
    let maxConfidence: Double
    
    var totalConfidence: Double {
        confidence * Double(sampleCount)
    }
    
    init(candidate: ClassificationCandidateImp, confidence: Double, maxIndex: Int, maxConfidence: Double) {
//        print("DavidoDebug: ConfidenceCount: \(candidate.passioID), \(confidence)")
        self.candidate = candidate
        self.confidence = confidence
        self.sampleCount = 1
        self.maxIndex = maxIndex
        self.maxConfidence = maxConfidence
    }

    init(confidenceData: TimeSeriesConfidenceCount, confidence: Double, maxIndex: Int, maxConfidence: Double) {
        self.candidate = confidenceData.candidate
        self.sampleCount = confidenceData.sampleCount + 1
        self.confidence = confidenceData.confidence.rollingAverage(value: confidence,
                                                                   averageCount: sampleCount)
        self.maxIndex = maxIndex
        self.maxConfidence = maxConfidence
    }
}

//
//  PaddedTextView.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class PaddedTextView: UITextView {
    enum QueuableMessage {
        case string(message: String, duration: Double?)
        case attributedString(message: NSAttributedString, duration: Double?)
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var textPadding: CGFloat = 0 {
        didSet {
            textContainerInset = UIEdgeInsets(top: textPadding,
                                              left: textPadding,
                                              bottom: textPadding,
                                              right: textPadding)
        }
    }
    
    private var messageQueue = [QueuableMessage]() {
        didSet {
            processQueue()
        }
    }
    private var isShowing = false
    
    func setFont(font: UIFont? = nil, color: UIColor? = nil) {
        if let font = font {
            self.font = font
        }
        if let color = color {
            self.textColor = color
        }
    }
    
    func enqueueMessage(message: String, duration: Double? = nil) {
        messageQueue.append(QueuableMessage.string(message: message, duration: duration))
    }
    
    func enqueueMessage(message: NSAttributedString, duration: Double? = nil) {
        messageQueue.append(QueuableMessage.attributedString(message: message, duration: duration))
    }
    
    func enqueueMessage(message: QueuableMessage) {
        messageQueue.append(message)
    }
    
    func enqueueMessages(messages: [QueuableMessage]) {
        messageQueue.append(contentsOf: messages)
    }
    
    func clearQueue() {
        messageQueue.removeAll()
        layer.removeAllAnimations()
        isHidden = true
        alpha = 0
    }
    
    private func show(message: QueuableMessage, completion: (() -> Void)? = nil) {
        layer.removeAllAnimations()
        isHidden = false
        alpha = 1
        var messageDuration: Double?
        
        switch message {
        case let .string(message, duration):
            text = message
            messageDuration = duration
            
        case let .attributedString(message, duration):
            var attributes = [NSAttributedString.Key: Any]()
            if let font = font,
               let existingSize = self.attributedText.font?.pointSize {
                attributes[NSAttributedString.Key.font] = font.withSize(existingSize)
            }
            if let textColor = textColor {
                attributes[NSAttributedString.Key.foregroundColor] = textColor
            }
            attributedText = message
            messageDuration = duration
        }
        
        guard let duration = messageDuration
        else {
            completion?()
            return
        }
        
        fadeMessage(duration: duration, completion: completion)
    }
    
    private func fadeMessage(duration: Double, completion: (() -> Void)? = nil) {
        alpha = 0

        UIView.animate(withDuration: 0.25, delay: 0,
                       options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            self?.alpha = 1
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            if self.messageQueue.isEmpty {
                UIView.animate(withDuration: 0.25, delay: duration, options: .curveEaseInOut) {
                    self.alpha = 0
                } completion: { _ in
                    completion?()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    completion?()
                }
            }
        }
    }
    
    private func processQueue() {
        guard !messageQueue.isEmpty,
              !isShowing
        else {
            return
        }
        
        isShowing = true
        let message = messageQueue.removeFirst()
        
        show(message: message) { [weak self] in
            self?.isShowing = false
            self?.processQueue()
        }
    }
}

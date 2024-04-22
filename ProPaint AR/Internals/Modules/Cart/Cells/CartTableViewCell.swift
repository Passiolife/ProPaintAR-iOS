//
//  CartTableViewCell.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/5/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import RemodelAR
import UIKit

class CartTableViewCell: UITableViewCell {
    @IBOutlet weak var paintSwatch: RoundedView!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var approximatePriceLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var coverageLabel: UILabel!
    @IBOutlet weak var coverageAmountLabel: UILabel!
    
    @IBOutlet weak var sheenLabel: UILabel!
    @IBOutlet weak var containerSizeLabel: UILabel!
    @IBOutlet weak var quantityTitleLabel: UILabel!
    
    @IBOutlet weak var sizeGallonLabel: UILabel!
    @IBOutlet weak var sizeSampleLabel: UILabel!
    @IBOutlet weak var sheenMatteLabel: UILabel!
    @IBOutlet weak var sheenEggshellLabel: UILabel!
    @IBOutlet weak var sheenSatinLabel: UILabel!
    @IBOutlet weak var sheenSemiglossLabel: UILabel!
    
    @IBOutlet weak var productImage: UIImageView!
    
    @IBOutlet weak var sizeGallon: UIStackView!
    @IBOutlet weak var sizeSample: UIStackView!
    
    @IBOutlet weak var sheenMatte: UIStackView!
    @IBOutlet weak var sheenEggshell: UIStackView!
    @IBOutlet weak var sheenSatin: UIStackView!
    @IBOutlet weak var sheenSemigloss: UIStackView!
    
    @IBOutlet weak var sheenMatteSelected: UIImageView!
    @IBOutlet weak var sheenEggshellSelected: UIImageView!
    @IBOutlet weak var sheenSatinSelected: UIImageView!
    @IBOutlet weak var sheenSemiglossSelected: UIImageView!
    
    @IBOutlet weak var sampleSizeImage: UIImageView!
    @IBOutlet weak var gallonSizeImage: UIImageView!
    
    @IBOutlet weak var sheenStackView: UIStackView!
    @IBOutlet weak var sizeStackView: UIStackView!
    @IBOutlet weak var outlineView: UIView!
    
    @IBOutlet weak var quantityStackView: UIStackView!
    @IBOutlet weak var quantityLabel: UILabel!
    
    @IBOutlet weak var paintedAreaStackView: UIStackView!
    @IBOutlet weak var paintedAreaTitleLabel: UILabel!
    @IBOutlet weak var paintedAreaLabel: UILabel!
    
    var selectedColor = UIColor.button
    
    var views: [UIStackView] {
        [sheenMatte, sheenEggshell, sheenSatin, sheenSemigloss]
    }
    
    var selectedViews: [UIImageView] {
        [sheenMatteSelected, sheenEggshellSelected, sheenSatinSelected, sheenSemiglossSelected]
    }
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    var item: CartItem!
    var costUpdated: (() -> Void)?
}

private typealias IBActions = CartTableViewCell
extension IBActions {
    @IBAction func sheenSelected(_ sender: UIButton) {
        guard let selected = item.selectedSize
        else { return }
        
        for sheen in selected.sheens
        where sheen.index == sender.tag {
            item.selectedSheen = sheen
            break
        }
        
        updateView()
    }
    
    @IBAction func sizeSelected(_ sender: UIButton) {
        for size in item.sizes
        where size.index == sender.tag {
            item.selectedSize = size
        }
        
        updateView()
        costUpdated?()
    }
    
    @IBAction func quantityAdd(_ sender: UIButton) {
        item.quantity = min(item.quantity + 1, 10)
        updateView()
        costUpdated?()
    }
    
    @IBAction func quantitySubtract(_ sender: UIButton) {
        item.quantity = max(item.quantity - 1, 0)
        updateView()
        costUpdated?()
    }
}

private typealias UIUpdate = CartTableViewCell
extension UIUpdate {
    func customizeView() {
        let darkTextColor = UIColor(hex: "333333")
        let lightTextColor = UIColor(hex: "c8c8c8")
        let paintColor = item.paint.paint.color
        let darkDistance = paintColor.distance(to: darkTextColor)
        let lightDistance = paintColor.distance(to: lightTextColor)
        var textColor = darkTextColor
        if darkDistance < lightDistance {
            textColor = lightTextColor
        }
        
        outlineView.layer.borderColor = UIColor(hex: "B9B9B9").cgColor
        outlineView.layer.borderWidth = 1
        outlineView.roundCorners(radius: 12)
        quantityStackView.roundCorners(radius: 18)
        
        colorLabel.textColor = textColor
        idLabel.textColor = textColor
        priceLabel.textColor = textColor
        approximatePriceLabel.textColor = textColor
        coverageLabel.textColor = textColor
        coverageAmountLabel.textColor = textColor
    }
    
    func configure(item: CartItem) {
        self.item = item
        
        paintedAreaStackView.isHidden = item.paint.area.area < 1
        paintedAreaLabel.text = "\((item.paint.area.area * 10.7639).truncated(decimals: 0)) sq ft"
        colorLabel.text = item.paint.paint.name
        idLabel.text = "\(item.paint.paint.id)"
        paintSwatch.backgroundColor = item.paint.paint.color
        
        customizeView()
        updateView()
    }
    
    func configureStyle(customizationRepo: CustomizationRepo?) {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let buttonColor = uiOptions.colors.button.color
        
        selectedColor = buttonColor
        
        colorLabel.font = uiOptions.font.font(with: 18)
        idLabel.font = uiOptions.font.font(with: 14)
        quantityLabel.font = uiOptions.font.font(with: 16)
        
        sheenLabel.textColor = textColor
        containerSizeLabel.textColor = textColor
        quantityTitleLabel.textColor = textColor
        
        approximatePriceLabel.font = uiOptions.font.font(with: 16)
        priceLabel.font = uiOptions.font.font(with: 27)
        coverageLabel.font = uiOptions.font.font(with: 9)
        coverageAmountLabel.font = uiOptions.font.font(with: 9)
        sheenLabel.font = uiOptions.font.font(with: 16)
        containerSizeLabel.font = uiOptions.font.font(with: 16)
        quantityTitleLabel.font = uiOptions.font.font(with: 16)
        paintedAreaTitleLabel.font = uiOptions.font.font(with: 15)
        paintedAreaLabel.font = uiOptions.font.font(with: 13)
        
        sizeGallonLabel.textColor = textColor
        sizeSampleLabel.textColor = textColor
        sheenMatteLabel.textColor = textColor
        sheenEggshellLabel.textColor = textColor
        sheenSatinLabel.textColor = textColor
        sheenSemiglossLabel.textColor = textColor
        
        sizeGallonLabel.font = uiOptions.font.font(with: 12)
        sizeSampleLabel.font = uiOptions.font.font(with: 12)
        sheenMatteLabel.font = uiOptions.font.font(with: 12)
        sheenEggshellLabel.font = uiOptions.font.font(with: 12)
        sheenSatinLabel.font = uiOptions.font.font(with: 12)
        sheenSemiglossLabel.font = uiOptions.font.font(with: 12)
        
        sheenMatteSelected.tintColor = buttonColor
        sheenEggshellSelected.tintColor = buttonColor
        sheenSatinSelected.tintColor = buttonColor
        sheenSemiglossSelected.tintColor = buttonColor
    }
    
    func updateView() {
        guard let item = item
        else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self
            else { return }
            
            self.quantityLabel.text = "\(item.quantity)"
            
            let formatter = NumberFormatter.currencyFormatter
            let number = NSNumber(value: item.cost)
            self.priceLabel.text = formatter.string(from: number)
            
            self.updateSize()
            self.updateSheen()
        }
    }
    
    func updateSize() {
        sizeGallon.isHidden = true
        sizeSample.isHidden = true
        
        for size in item.sizes {
            switch size {
            case .gallon:
                sizeGallon.isHidden = false
                
            case .sample:
                sizeSample.isHidden = false
            }
        }
        
        if let selected = item.selectedSize {
            var gallonTint = UIColor.gray
            var sampleTint = UIColor.gray
            switch selected {
            case .gallon:
                coverageAmountLabel.text = "400 sq.ft. per gallon"
                gallonTint = selectedColor
                productImage.image = UIImage(named: "tributePaint")
                gallonSizeImage.image = UIImage(named: "gallonSelected")
                sampleSizeImage.image = UIImage(named: "sample")
                
            case .sample:
                coverageAmountLabel.text = "25 sq.ft. per 8 fl oz"
                sampleTint = selectedColor
                productImage.image = UIImage(named: "tributePaintSample")
                gallonSizeImage.image = UIImage(named: "gallon")
                sampleSizeImage.image = UIImage(named: "sampleSelected")
            }
            gallonSizeImage.tintColor = gallonTint
            sampleSizeImage.tintColor = sampleTint
            
            let selectedSheenIndex = item.selectedSheen?.index ?? 0
            
            for sheen in 0..<4 {
                let visible = selected.sheens.contains(where: {
                    $0.index == sheen
                })
                views[sheen].isHidden = !visible
                selectedViews[sheen].isHidden = sheen != selectedSheenIndex
            }
        }
    }
    
    func updateSheen() {
        for sheen in 0..<4 {
            let selected = item.selectedSheen?.index == sheen
            selectedViews[sheen].isHidden = !selected
        }
    }
}

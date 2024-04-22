//
//  CartViewController.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/4/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import RemodelAR
import UIKit

protocol CartViewControllerDelegate: AnyObject {
    func dismiss(_ controller: CartViewController)
}

class CartViewController: UIViewController, Trackable {
    weak var delegate: CartViewControllerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userHint: PaddedTextView!
    @IBOutlet weak var homeButton: ImageButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkoutButton: UIButton!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var totalTitleLabel: UILabel!
    
    private var cancellables = Set<AnyCancellable>()
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cartRepo: CartRepo!
    var customizationRepo: CustomizationRepo?
    
    internal static func instantiate(
        cartRepo: CartRepo,
        customizationRepo: CustomizationRepo?
    ) -> Self {
        let vc = Self.instantiate(fromStoryboardNamed: .ARMethods)
        vc.cartRepo = cartRepo
        vc.customizationRepo = customizationRepo
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cartRepo.itemsPublisher.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateTotal()
            }
        }.store(in: &cancellables)

        tableView.register(UINib(nibName: "CartTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "CartTableViewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyUICustomization()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 560
        tableView.separatorStyle = .none
        tableView.reloadData()
        updateTotal()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        trackScreen(name: "cart", parameters: nil)
    }
    
    func updateTotal() {
        let formatter = NumberFormatter.currencyFormatter
        let number = NSNumber(value: cartRepo.total)
        let string = formatter.string(from: number)
        totalLabel.text = string
    }
}

private typealias IBActions = CartViewController
extension IBActions {
    @IBAction func homeTapped(_ sender: Any) {
        trackEvent(name: "cart closed", parameters: nil)
        delegate?.dismiss(self)
    }
    
    @IBAction func saveImageTapped(_ sender: Any) {
        if let screenshot = tableView.screenshot {
            trackEvent(name: "save cart image", parameters: nil)
            UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
            userHint.enqueueMessage(message: "Cart Saved to Photos!",
                                    duration: 4)
        }
    }
    
    @IBAction func checkoutAction(_ sender: Any) {
        cartRepo.performCheckout()
    }
}

private typealias Configuration = CartViewController
extension Configuration {
    private func applyUICustomization() {
        guard let customizationRepo = customizationRepo
        else { return }
        
        let uiOptions = customizationRepo.options.uiOptions
        let textColor = uiOptions.colors.text.color
        let buttonTextColor = uiOptions.colors.buttonText.color
        let buttonColor = uiOptions.colors.button.color
        let home = uiOptions.buttonIcons.homeIcon
        
        homeButton.imageView.setImage(with: home)
        
        titleLabel.font = uiOptions.font.font(with: 20)
        titleLabel.textColor = textColor
        
        checkoutButton.titleLabel?.font = uiOptions.font.font(with: 14)
        checkoutButton.setTitleColor(buttonTextColor, for: .normal)
        checkoutButton.backgroundColor = buttonColor
        
        totalTitleLabel.textColor = textColor
        totalLabel.textColor = textColor
        totalTitleLabel.font = uiOptions.font.font(with: 16)
        totalLabel.font = uiOptions.font.font(with: 34)
    }
}

private typealias Table = CartViewController
extension Table: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cartRepo.items.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        // swiftlint:disable:next line_length
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CartTableViewCell.identifier) as? CartTableViewCell
        else {
            // swiftlint:disable:next line_length
            fatalError("Failed to get expected kind of reusable cell from the tableView. Expected type `CartTableViewCell`")
        }
        
        let item = cartRepo.items[indexPath.row]
        cell.configure(item: item)
        cell.configureStyle(customizationRepo: customizationRepo)
        cell.costUpdated = { [weak self] in
            self?.updateTotal()
        }
        return cell
    }
}

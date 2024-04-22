//
//  PaintPickerView.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 12/05/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

enum PaintCollection {
    case primary
    case secondary
}

final class PaintPickerView: UIView {
    private var primaryPaints: [Paint] = [] {
        didSet {
            primaryCollectionView.reloadData()
        }
    }
    private var secondaryPaints: [Paint] = [] {
        didSet {
            secondaryCollectionView.reloadData()
        }
    }
    
    private lazy var primaryCollectionView: InfiniteCollectionView = {
        let collectionView = InfiniteCollectionView(
            frame: .zero,
            collectionViewLayout: primaryCollectionFlowLayout
        )
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var secondaryCollectionView: InfiniteCollectionView = {
        let collectionView = InfiniteCollectionView(
            frame: .zero,
            collectionViewLayout: secondaryCollectionFlowLayout,
            isSecondaryCollectionView: true)
        collectionView.delegate = self
        collectionView.transform = secondaryPaintsTransform
        collectionView.alpha = 0
        collectionView.indexOffset = 0
        return collectionView
    }()
    
    var primaryPaintFont: UIFont {
        primaryPaintTitleLabel.font
    }
    
    var secondaryPaintFont: UIFont {
        secondaryPaintTitleLabel.font
    }
    
    private lazy var primaryPaintTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .black
        titleLabel.text = ""
        return titleLabel
    }()
    
    private lazy var secondaryPaintTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .black
        titleLabel.text = ""
        titleLabel.isHidden = true
        return titleLabel
    }()
    
    private lazy var paintLabelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing   = 10
        return stackView
    }()

    private let primaryCollectionFlowLayout = CarouselCollectionFlowLayout()
    private let secondaryCollectionFlowLayout = CarouselCollectionFlowLayout()
    private var primaryPaintIndex: Int = 0 {
        didSet {
            configureSecondaryPaints()
        }
    }
    
    private lazy var secondaryPaintsTransform = CGAffineTransform(
        translationX: 0, y: -40
    )
    
    private lazy var primaryPaintsTransform = CGAffineTransform(
        translationX: 0, y: 40
    ).scaledBy(x: 0.9, y: 0.9)
    
    private let touchOverlayView = UIView()
    // used only for fewer paint item to show border
    private var secondaryPaintIndex: Int = 0 {
        didSet {
            secondaryCollectionView.reloadItems(at: [[0, secondaryPaintIndex], [0, oldValue]])
        }
    }
    private var isFewPaints: Bool {
        secondaryPaints.count < 5
    }

    var enableHapticFeedback = false
    private var hapticFeedbackOccured = false

    var enableTapToOpenSecondaryPaints = true
    private var isHiddenSecondaryPaints = true
    var hidesSecondaryPaintOnBottomTap = true

    weak var dataSource: PaintPickerDataSource? {
        didSet {
            guard let dataSource = dataSource else {
                return
            }
            primaryPaints = dataSource.paints(for: self)
        }
    }
    weak var delegate: PaintPickerDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadViews()
        configurations()
    }
    
    func reloadPicker() {
        guard let dataSource = dataSource else {
            return
        }
        primaryPaints = dataSource.paints(for: self)
        if !primaryPaints.isEmpty { primaryPaintIndex = 0 }
    }

    func reloadPicker(for picker: PaintCollection) {
        switch picker {
        case .primary:
            primaryCollectionView.reloadData()

        case .secondary:
            secondaryCollectionView.reloadData()
        }
    }

    func configurePrimaryTitleLabelStyle(
        _ font: UIFont? = nil,
        _ textColor: UIColor? = nil
    ) {
        primaryPaintTitleLabel.textAlignment = .center
        primaryPaintTitleLabel.contentMode = .center
        primaryPaintTitleLabel.adjustsFontSizeToFitWidth = true
        primaryPaintTitleLabel.minimumScaleFactor = 0.5
        
        if let font = font {
            primaryPaintTitleLabel.font = font
        }
        if let textColor = textColor {
            primaryPaintTitleLabel.textColor = textColor
        }
    }
    
    func configureSecondaryTitleLabelStyle(
        _ font: UIFont? = nil,
        _ textColor: UIColor? = nil
    ) {
        secondaryPaintTitleLabel.textAlignment = .center
        secondaryPaintTitleLabel.contentMode = .center
        secondaryPaintTitleLabel.adjustsFontSizeToFitWidth = true
        secondaryPaintTitleLabel.minimumScaleFactor = 0.5
        
        if let font = font {
            secondaryPaintTitleLabel.font = font
        }
        if let textColor = textColor {
            secondaryPaintTitleLabel.textColor = textColor
        }
    }
    
    func scrollToPaint(
        for paintType: PaintCollection,
        at indexPath: IndexPath,
        animated: Bool = true
    ) {
        switch paintType {
        case .primary:
            primaryCollectionView.indexOffset = 0
            let actualIndexPath = IndexPath(row: indexPath.row + primaryCollectionView.indexOffset,
                                            section: indexPath.section)
            primaryCollectionView.scrollToItem(at: actualIndexPath,
                                               at: .centeredHorizontally,
                                               animated: animated)

        case .secondary:
            secondaryCollectionView.indexOffset = 0
            let actualIndexPath = IndexPath(row: indexPath.row + secondaryCollectionView.indexOffset,
                                            section: indexPath.section)
            secondaryCollectionView.scrollToItem(at: actualIndexPath,
                                                 at: .centeredHorizontally,
                                                 animated: animated)
        }
    }
}

extension PaintPickerView {
    private func loadViews() {
        loadCollectionView(primaryCollectionView)
        loadCollectionView(secondaryCollectionView)
        loadLabels()
    }
    
    private func configurations() {
        configure(for: primaryCollectionView)
        configure(for: secondaryCollectionView)
        configureSwipeUpGesture()
    }
}
// MARK: Load views
extension PaintPickerView {
    func loadCollectionView(_ collectionView: InfiniteCollectionView) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.frame = bounds
        addSubview(containerView)

        let containerConstraints = [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor)
        ]

        NSLayoutConstraint.activate(containerConstraints)
        
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(collectionView)
        
        let constraints = [
            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            collectionView.topAnchor.constraint(equalTo: containerView.topAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        // Touch overlay
        if collectionView == secondaryCollectionView {
            touchOverlayView.translatesAutoresizingMaskIntoConstraints = false
            touchOverlayView.frame = bounds
            let gesture = UITapGestureRecognizer(
                target: self,
                action: #selector(handleOverlayTap)
            )
            gesture.numberOfTapsRequired = 1
            touchOverlayView.isUserInteractionEnabled = true
            touchOverlayView.addGestureRecognizer(gesture)
            touchOverlayView.backgroundColor = .clear
            let touchOverlayConstraints = [
                touchOverlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 10),
                touchOverlayView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                touchOverlayView.heightAnchor.constraint(equalToConstant: 40),
                touchOverlayView.widthAnchor.constraint(equalTo: widthAnchor)
            ]
            containerView.addSubview(touchOverlayView)
            NSLayoutConstraint.activate(touchOverlayConstraints)
            let frontView = primaryCollectionView.superview ?? UIView()
            primaryCollectionView.superview?.superview?.bringSubviewToFront(frontView)
        }
    }
    
    func loadLabels() {
        addSubview(paintLabelStackView)
        paintLabelStackView.addArrangedSubview(primaryPaintTitleLabel)
        paintLabelStackView.addArrangedSubview(secondaryPaintTitleLabel)
        paintLabelStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paintLabelStackView.bottomAnchor.constraint(equalTo: topAnchor),
            paintLabelStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            paintLabelStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

// MARK: Configuration
extension PaintPickerView {
    private func configurePrimaryPaintLabel(with title: String) {
        primaryPaintTitleLabel.text = title
    }

    private func configureSecondaryPaintLabel(with title: String) {
        secondaryPaintTitleLabel.text = title
    }

    private func configure(for collectionView: InfiniteCollectionView) {
        collectionView.register(
            UINib(nibName: "WallColorCollectionCell", bundle: nil),
            forCellWithReuseIdentifier: "WallColorCollectionCell"
        )
        collectionView.infiniteDataSource = self
        collectionView.infiniteDelegate = self
    }
    
    private func configureSecondaryPaints() {
        configurePrimaryPaintLabel(with: primaryPaints[primaryPaintIndex].name)
        secondaryPaints = primaryPaints[primaryPaintIndex].secondaryColors
        if !secondaryPaints.isEmpty {
            secondaryCollectionView.scrollToIndexPath([0, 0], animated: false)
            configureSecondaryPaintLabel(with: secondaryPaints[0].name)
        }
        secondaryCollectionFlowLayout.updateLayout()
        secondaryCollectionFlowLayout.updateLayout()
        secondaryCollectionView.updateNavigationStackView()
    }
    
    private func configureSwipeUpGesture() {
        let swipeGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(swipedDownRecognize)
        )
        swipeGesture.direction = .up
        self.addGestureRecognizer(swipeGesture)
    }
}

// MARK: Actions
extension PaintPickerView {
    @objc func handleOverlayTap() {
        guard hidesSecondaryPaintOnBottomTap else { return }
        swipedDownRecognize()
    }

    @objc private func swipedDownRecognize() {
        if !isHiddenSecondaryPaints {
            hideSecondaryPaintPicker()
        }
    }

    func hideSecondaryPaintPicker() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.primaryCollectionView.superview?.transform = .identity
            self.secondaryCollectionView.transform = self.secondaryPaintsTransform
            self.secondaryCollectionView.alpha = 0
            let frontView = self.primaryCollectionView.superview ?? UIView()
            self.primaryCollectionView.superview?.superview?.bringSubviewToFront(frontView)
            self.delegate?.secondaryPaintPickerView(self, dismiss: true)
            self.secondaryPaintTitleLabel.alpha = 0
            self.secondaryPaintTitleLabel.isHidden = true
            if self.isFewPaints {
                self.secondaryPaintIndex = 0
            }
            self.isHiddenSecondaryPaints = true
        } completion: { [weak self] _ in
            self?.reloadPicker(for: .primary)
        }
    }

    private func showSecondaryPaintPicker() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.secondaryCollectionView.transform = .identity
            self.secondaryCollectionView.alpha = 1
            self.secondaryCollectionView.indexOffset = 0
            let frontView = self.secondaryCollectionView.superview ?? UIView()
            self.secondaryCollectionView.superview?.superview?.bringSubviewToFront(frontView)
            self.primaryCollectionView.superview?.transform = self.primaryPaintsTransform
            self.secondaryPaintTitleLabel.alpha = 1
            self.secondaryPaintTitleLabel.isHidden = false
            self.isHiddenSecondaryPaints = false
        }
    }

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func handleHapticFeedback(with index: Int) {
        if index == 0,
           enableHapticFeedback,
           !hapticFeedbackOccured {
            hapticFeedbackOccured = true
            hapticFeedback()
        } else if index != 0 {
            hapticFeedbackOccured = false
        }
    }
    
    private func updateCellDistance(for collectionView: UICollectionView) {
        for cell in collectionView.visibleCells.compactMap({ $0 as? WallColorCollectionCell }) {
            let visibleRect = CGRect(
                origin: collectionView.contentOffset,
                size: collectionView.frame.size
            )
            cell.distanceFromCenter = visibleRect.midX - cell.frame.midX
        }
    }
}

extension PaintPickerView: InfiniteCollectionViewDelegate {
    func onPaintItemTapped(_ collectionView: UICollectionView, indexPath: IndexPath, offset: Int) {
        if !isFewPaints {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.updateCellDistance(for: collectionView)
            }
        }
        if collectionView == primaryCollectionView {
            delegate?.paintPickerView(self,
                                      didSelectPaintAt: indexPath,
                                      primary: primaryPaints[indexPath.row])
            primaryPaintIndex = indexPath.row
            if enableTapToOpenSecondaryPaints {
                showSecondaryPaintPicker()
            } else {
                // double tap require to open secondary paint
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    if let primaryIndexPath = self.primaryCollectionFlowLayout.currentCenteredIndexPath {
                        let actualIndex = self.primaryCollectionView.findActualIndex(for: primaryIndexPath.row)
                        if actualIndex == indexPath.row,
                           self.isHiddenSecondaryPaints {
                            self.showSecondaryPaintPicker()
                        }
                    }
                }
            }
        } else if collectionView == secondaryCollectionView {
            delegate?.paintPickerView(self,
                                      didSelectPaintAt: indexPath,
                                      secondary: secondaryPaints[indexPath.row])
            if isFewPaints {
                secondaryPaintIndex = indexPath.row
                configureSecondaryPaintLabel(with: secondaryPaints[indexPath.row].name)
            }
        }
    }
}

extension PaintPickerView: InfiniteCollectionViewDataSource {
    func cellForItemAtIndexPath(
        _ collectionView: UICollectionView,
        dequeueIndexPath: IndexPath,
        usableIndexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "WallColorCollectionCell", for: dequeueIndexPath
        ) as? WallColorCollectionCell
        else { return UICollectionViewCell() }
        cell.configure(with: dataSource?.paintPickerView(self, cornerRadiusFor: usableIndexPath))
        cell.configure(with: dataSource?.paintPickerView(self, shadowFor: usableIndexPath))
        if usableIndexPath.row != 0 {
            cell.clearBorderColor()
        }
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)
        cell.distanceFromCenter = visibleRect.midX - cell.frame.midX
        if collectionView == primaryCollectionView {
            // primary
            let paint = primaryPaints[usableIndexPath.row]
            cell.configure(
                with: paint,
                borderWidth: (dataSource?.primaryPaintPickerView(self,
                                                                 borderWidthFor: usableIndexPath) ?? 0.0),
                borderColor: dataSource?.primaryPaintPickerView(self,
                                                                borderColorFor: usableIndexPath),
                paintImage: dataSource?.primaryPaintPickerView(self,
                                                               imageFor: usableIndexPath)
            )
            return cell
        } else if collectionView == secondaryCollectionView {
            let paint = secondaryPaints[usableIndexPath.row]
            cell.configure(with: paint,
                           borderWidth: (dataSource?.secondaryPaintPickerView(
                            self,
                            borderWidthFor: usableIndexPath,
                            primaryPaint: primaryPaintIndex
                           ) ?? 0.0),
                           borderColor: dataSource?.secondaryPaintPickerView(
                            self,
                            borderColorFor: usableIndexPath,
                            primaryPaint: primaryPaintIndex
                           ),
                           paintImage: dataSource?.secondaryPaintPickerView(
                            self,
                            imageFor: usableIndexPath,
                            primaryPaint: primaryPaintIndex
                           ))
            if isFewPaints {
                cell.handleFewPaintBorder(with: secondaryPaints[secondaryPaintIndex].id, paint: paint)
            }

            return cell
        }
        return UICollectionViewCell()
    }

    func numberOfItems(_ collectionView: UICollectionView) -> Int {
        if collectionView == primaryCollectionView {
            return primaryPaints.count
        } else if collectionView == secondaryCollectionView {
            return secondaryPaints.count
        }
        return 0
    }
}

extension PaintPickerView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? InfiniteCollectionView,
              scrollView.isDragging
        else { return }
        updateCellDistance(for: collectionView)
        if collectionView == primaryCollectionView {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if let indexPath = self.primaryCollectionFlowLayout.currentCenteredIndexPath {
                    let actualIndex = self.primaryCollectionView.findActualIndex(for: indexPath.row)
                    self.configurePrimaryPaintLabel(with: self.primaryPaints[actualIndex].name)
                    self.delegate?.paintPickerViewDidScroll(self, primary: self.primaryPaints[actualIndex])
                    self.handleHapticFeedback(with: actualIndex)
                }
            }
        } else if collectionView == secondaryCollectionView {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if let indexPath = self.secondaryCollectionFlowLayout.currentCenteredIndexPath {
                    let actualIndex = self.secondaryCollectionView.findActualIndex(for: indexPath.row)
                    self.configureSecondaryPaintLabel(with: self.secondaryPaints[actualIndex].name)
                    self.delegate?.paintPickerViewDidScroll(self, secondary: self.secondaryPaints[actualIndex])
                    self.handleHapticFeedback(with: actualIndex)
                }
            }
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? InfiniteCollectionView,
              collectionView == secondaryCollectionView
        else { return }
        if let indexPath = secondaryCollectionFlowLayout.currentCenteredIndexPath {
            let actualIndex = secondaryCollectionView.findActualIndex(for: indexPath.row)
            configureSecondaryPaintLabel(with: secondaryPaints[actualIndex].name)
        }
    }
}

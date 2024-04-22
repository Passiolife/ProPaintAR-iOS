//
//  InfiniteCollectionView.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 12/05/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

protocol InfiniteCollectionViewDataSource: AnyObject {
    func cellForItemAtIndexPath(
        _ collectionView: UICollectionView,
        dequeueIndexPath: IndexPath,
        usableIndexPath: IndexPath
    ) -> UICollectionViewCell
    func numberOfItems(_ collectionView: UICollectionView) -> Int
}

protocol InfiniteCollectionViewDelegate: AnyObject {
    func onPaintItemTapped(_ collectionView: UICollectionView, indexPath: IndexPath, offset: Int)
}

class InfiniteCollectionView: UICollectionView {
    let isSecondaryCollectionView: Bool
    
    weak var infiniteDataSource: InfiniteCollectionViewDataSource?
    weak var infiniteDelegate: InfiniteCollectionViewDelegate?
    
    private var flowLayout: CarouselCollectionFlowLayout? {
        collectionViewLayout as? CarouselCollectionFlowLayout
    }
    
    var firstScrollTime = true
    
    var cellCount: Int {
        infiniteDataSource?.numberOfItems(self) ?? 0
    }
    
    var repeatCount: Int {
        guard cellCount > 4 else { return 1 }
        
        /* The number 401 was chosen because of a technicality. It has to do with the scrolling
         inertia of the collection view and some UIScrollView delegate stuff in the background
         that won't work properly if the number of items were less (To make a long story short,
         the scroll view deceleration animation needs a proper amount of space to calculate the
         ending point of the deceleration and if there are too few items in the collection view,
         it would stop at an incorrect x coordinate otherwise)
         */
        var multiplier = 1
        if cellCount < 80 {
            multiplier = 80 / cellCount
        }
        return multiplier
    }
    
    fileprivate var contentWidth: CGFloat {
        CGFloat(cellCount) * (cellWidth + cellPadding)
    }
    
    let maxWidth: CGFloat = 500
    
    var previousScreenWidth: CGFloat = .nan
    
    fileprivate var cellPadding: CGFloat = 0
    fileprivate var cellWidth: CGFloat = 0
    fileprivate var cellHeight: CGFloat = 0
    
    var indexOffset = 0
    
    fileprivate var navigationCarouselButtonCount: Int {
        Int(min(maxWidth, UIScreen.main.bounds.width) / 80) * 2 + 1
    }

    let navigationStackView = UIStackView()
    var navigationStackConstraints = [NSLayoutConstraint]()

    var currentIndexPath: IndexPath? {
        let indexPaths = indexPathsForVisibleItems.sorted()
        let index = (indexPathsForVisibleItems.count - 1) / 2
        if indexPaths.count <= index { return nil }
        return indexPaths[index]
    }
    
    init(
        frame: CGRect,
        collectionViewLayout layout: UICollectionViewLayout,
        isSecondaryCollectionView: Bool = false
    ) {
        self.isSecondaryCollectionView = isSecondaryCollectionView
        super.init(frame: frame, collectionViewLayout: layout)
        dataSource = self
        contentInset = .zero
        contentInsetAdjustmentBehavior = .always
        showsHorizontalScrollIndicator = false
        setupCellDimensions()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.isSecondaryCollectionView = false
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let screenWidth = UIScreen.main.bounds.width
        let numberOfItems = numberOfItems(inSection: 0)
        if previousScreenWidth != screenWidth {
            previousScreenWidth = screenWidth
            flowLayout?.updateLayout()
            setupCellDimensions()
            updateNavigationStackView()
        }
        navigationStackView.frame = bounds

        guard numberOfItems > 4 else { return }
        let currentOffset = contentOffset
        let contentWidth = self.contentWidth
        let centerOffsetX = (CGFloat(repeatCount) * contentWidth - bounds.size.width) / 2
        let distanceFromCenter = centerOffsetX - currentOffset.x

        guard abs(distanceFromCenter) > contentWidth / 4 else { return }
        let cellDistance = distanceFromCenter / (cellWidth + cellPadding)
        let shiftCells = Int((cellDistance > 0) ? floor(cellDistance) : ceil(cellDistance))
        let cellDistanceRemainder = (abs(cellDistance).truncatingRemainder(dividingBy: 1))
        var offsetCorrection = cellDistanceRemainder * (cellWidth + cellPadding)
        offsetCorrection *= contentOffset.x < centerOffsetX ? -1 : 1
        contentOffset = .init(x: centerOffsetX + offsetCorrection, y: currentOffset.y)

        indexOffset += getCorrectedIndex(shiftCells)
        reloadData()
    }
    
    fileprivate func setupCellDimensions() {
        guard let flowLayout = flowLayout else { return }
        cellPadding = flowLayout.minimumInteritemSpacing
        cellWidth = flowLayout.itemSize.width
        cellHeight = flowLayout.itemSize.height
    }
    
    func updateNavigationStackView() {
        for subview in navigationStackView.arrangedSubviews {
            navigationStackView.removeArrangedSubview(subview)
        }
        let startPlaceholderView = UIView()
        navigationStackView.addArrangedSubview(startPlaceholderView)
        updateNavigationButtons()
        let endPlaceholderView = UIView()
        navigationStackView.addArrangedSubview(endPlaceholderView)
        endPlaceholderView.widthAnchor.constraint(equalTo: startPlaceholderView.widthAnchor).isActive = true
        navigationStackView.axis = .horizontal
        navigationStackView.distribution = .fill
        navigationStackView.alignment = .fill
        navigationStackView.spacing = 0
        navigationStackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if navigationStackView.superview == nil {
            addSubview(navigationStackView)
        }
    }
    
    fileprivate func updateNavigationButtons() {
        let isFewColors = (1 ... 4).contains(numberOfItems(inSection: 0))
        let buttonCount = navigationCarouselButtonCount
        let maxIndex = (buttonCount - 1) / 2

        let range: ClosedRange<Int> = {
            if isFewColors {
                return 0 ... numberOfItems(inSection: 0) - 1
            }
            return -maxIndex ... maxIndex
        }()

        for index in range {
            let navigationView = UIView()
            navigationView.tag = index
            let tapGestRec = UITapGestureRecognizer()
            tapGestRec.addTarget(self, action: #selector(navigationTapped(_:)))
            navigationView.addGestureRecognizer(tapGestRec)
            let constant: CGFloat = {
                if let flowLayout = flowLayout,
                   isFewColors {
                    return flowLayout.standardSize + flowLayout.standardSpacing
                }
                if index == 0 { return 72 }
                let percentage = CGFloat(maxIndex - abs(index)) / CGFloat(maxIndex)
                let base = min(maxWidth, UIScreen.main.bounds.width) / 11
                return base * 0.8 + base * 0.2 * percentage
            }()
            let widthConstraint = navigationView.widthAnchor.constraint(
                equalToConstant: constant
            )
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
            navigationStackConstraints.append(widthConstraint)
            navigationStackView.addArrangedSubview(navigationView)
            
//             Uncomment to debug
//             navigationView.layer.borderWidth = 2
//             navigationView.layer.borderColor = UIColor.blue.cgColor
        }
    }
    
    func getCorrectedIndex(_ indexToCorrect: Int) -> Int {
        guard let numberOfCells = infiniteDataSource?.numberOfItems(self),
              numberOfCells != 0
        else { return 0 }

        if indexToCorrect < numberOfCells && indexToCorrect >= 0 {
            return indexToCorrect
        }

        let countInIndex = Float(indexToCorrect) / Float(numberOfCells)
        let flooredValue = Int(floor(countInIndex))
        let offset = numberOfCells * flooredValue

        return min(numberOfCells - 1, indexToCorrect - offset)
    }
    
    func scrollToIndexPath(_ indexPath: IndexPath, animated: Bool = true) {
        // deliberately called twice (iOS is a buggy mess and this doesn't work otherwise)
        scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    @objc fileprivate func navigationTapped(_ sender: UITapGestureRecognizer) {
        guard let currentIndexPath = currentIndexPath else { return }

        let offset = sender.view?.tag ?? 0
        var itemIndex: Int
        if numberOfItems(inSection: 0) < 5 {
            itemIndex = offset
        } else {
            itemIndex = currentIndexPath.item + offset
        }
        let indexPath = IndexPath(item: itemIndex, section: 0)
        if numberOfItems(inSection: 0) > 4 {
            scrollToIndexPath(indexPath)
        }
        let actualIndex = getCorrectedIndex(indexPath.item - indexOffset)
        let actualIndexPath = IndexPath(row: actualIndex, section: 0)
        infiniteDelegate?.onPaintItemTapped(self, indexPath: actualIndexPath, offset: offset)
    }

    func findActualIndex(for index: Int) -> Int {
        let actualIndex = getCorrectedIndex(index - indexOffset)
        return actualIndex
    }
}

// MARK: UICollectionView DataSource

extension InfiniteCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = infiniteDataSource
        else { return 0 }
        return repeatCount * dataSource.numberOfItems(self)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let dataSource = infiniteDataSource
        else { return .init() }
        return dataSource.cellForItemAtIndexPath(
            self,
            dequeueIndexPath: indexPath,
            usableIndexPath: .init(item: getCorrectedIndex(indexPath.item - indexOffset), section: 0)
        )
    }
}

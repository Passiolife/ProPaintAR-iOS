//
//  CarouselCollectionFlowLayout.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 12/05/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

class CarouselCollectionFlowLayout: UICollectionViewFlowLayout {
    private let offsetModeThreshold: CGFloat = 5
    private let zoomedOutFactor: CGFloat = 0.5
    private let offsetExponentialBaseNumber: CGFloat = 2.4
    private var zoomActivationDistance: CGFloat {
        min(maxWidth, UIScreen.main.bounds.width) / 2
    }
    private var maxWidth: CGFloat {
        (collectionView as? InfiniteCollectionView)?.maxWidth ?? 0
    }
    private var offsetDistanceDividend: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(60, screenWidth / 9)
    }
    private var offsetCenterTargetOffset: CGFloat {
        pow(offsetExponentialBaseNumber, offsetModeThreshold / offsetDistanceDividend)
    }
    /// Calculates the current centered page.
    var currentCenteredIndexPath: IndexPath? {
        guard let collectionView = self.collectionView else { return nil }
        let xPosition = collectionView.contentOffset.x + collectionView.bounds.width / 2
        let yPosition = collectionView.contentOffset.y + collectionView.bounds.height / 2
        let currentCenteredPoint = CGPoint(x: xPosition, y: yPosition)
        return collectionView.indexPathForItem(at: currentCenteredPoint)
    }
    let standardSize: CGFloat = 72
    let standardSpacing: CGFloat = 8
    
    override init() {
        super.init()

        scrollDirection = .horizontal
        minimumInteritemSpacing = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateLayout() {
        guard let collectionView = collectionView else {
            return
        }
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let screenWidth = UIScreen.main.bounds.width
        
        if !(1 ... 4).contains(numberOfItems) {
            let inset = collectionView.adjustedContentInset
            let horizontalInsets = (collectionView.frame.width - inset.right - inset.left - itemSize.width) / 2
            
            sectionInset = .init(
                top: 0,
                left: horizontalInsets,
                bottom: 0,
                right: horizontalInsets
            )
            minimumLineSpacing = 0
            itemSize = .init(
                width: round(min(maxWidth, screenWidth) / 10),
                height: collectionView.bounds.height
            )
        } else {
            let spacings = standardSpacing * CGFloat(numberOfItems - 1)
            let horizontalInsets = (screenWidth - (standardSize * CGFloat(numberOfItems) + spacings)) / 2
            
            sectionInset = .init(
                top: 0,
                left: horizontalInsets,
                bottom: 0,
                right: horizontalInsets
            )
            
            minimumLineSpacing = standardSpacing
            
            itemSize = .init(
                width: standardSize,
                height: collectionView.bounds.height
            )
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView,
              let superAttributes = super.layoutAttributesForElements(in: rect),
              collectionView.numberOfItems(inSection: 0) > 4 else {
                  return super.layoutAttributesForElements(in: rect)
              }
        let offsetCenterTargetOffset = self.offsetCenterTargetOffset
        
        let rectAttributes = superAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)
        for attributes in rectAttributes where attributes.frame.intersects(visibleRect) {
            let distance = visibleRect.midX - attributes.center.x
            let normalizedDistance = distance / zoomActivationDistance
            let zoom = 1 - (1 - zoomedOutFactor) * (normalizedDistance.magnitude)
            let offsetX: CGFloat = {
                if abs(distance) < offsetModeThreshold {
                    return distance / offsetModeThreshold * offsetCenterTargetOffset
                }
                
                return (distance > 0 ? 1 : -1) * pow(offsetExponentialBaseNumber,
                                                     abs(distance / offsetDistanceDividend))
            }()
            let scaleTransform = CATransform3DMakeScale(zoom, zoom, 1)
            let offsetTransform = CATransform3DMakeTranslation(offsetX, 0, 0)
            attributes.transform3D = CATransform3DConcat(scaleTransform, offsetTransform)
            
            attributes.zIndex = Int((zoom * 100).rounded())
            attributes.isHidden = abs(offsetX) > 100
        }
        return rectAttributes
    }
    
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let collectionView = collectionView,
              collectionView.numberOfItems(inSection: 0) > 4 else {
                  return super.targetContentOffset(
                    forProposedContentOffset: proposedContentOffset,
                    withScrollingVelocity: velocity
                  )
              }
        let targetRect = CGRect(
            x: proposedContentOffset.x,
            y: 0,
            width: collectionView.frame.width,
            height: collectionView.frame.height
        )
        guard let rectAttributes = super.layoutAttributesForElements(in: targetRect) else {
            return .zero
        }
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalCenter = proposedContentOffset.x + collectionView.frame.width / 2
        for layoutAttributes in rectAttributes {
            let itemHorizontalCenter = layoutAttributes.center.x
            
            if (itemHorizontalCenter - horizontalCenter).magnitude < offsetAdjustment.magnitude {
                offsetAdjustment = itemHorizontalCenter - horizontalCenter
            }
        }
        return .init(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        (collectionView?.numberOfItems(inSection: 0) ?? 0) > 4
    }

    override func invalidationContext(
        forBoundsChange newBounds: CGRect
    ) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forBoundsChange: newBounds)
        guard let flowContext = superContext as? UICollectionViewFlowLayoutInvalidationContext else {
            return .init()
        }
        guard let collectionView = collectionView,
              collectionView.numberOfItems(inSection: 0) > 4 else {
                  return superContext
              }
        flowContext.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView.bounds.size
        return flowContext
    }
}

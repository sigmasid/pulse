//
//  PulseAlbumView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/27/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import Photos

public protocol AlbumViewDelegate: class {
    func albumViewCameraRollUnauthorized()
    func selectedImage(image : UIImage?, metaData: ImageMetadata?)
    func selectedVideo(video : PHAsset?, metaData: ImageMetadata?)
}

class PulseAlbumView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate {
    
    public var currentMode : CreatedAssetType = .albumImage {
        didSet {
            if currentMode != oldValue {
                switch currentMode {
                case .albumImage:
                    collectionView.reloadData()
                    resetCachedAssets()
                case .albumVideo:
                    getVideos()
                    resetCachedAssets()
                default: break
                }
            }
        }
    }
    var collectionView: UICollectionView!
    weak var delegate: AlbumViewDelegate? = nil
    
    fileprivate var images: PHFetchResult<PHAsset>!
    fileprivate var videos: PHFetchResult<PHAsset>!
    
    fileprivate var imageManager: PHCachingImageManager?
    
    fileprivate var previousPreheatRect: CGRect = .zero
    fileprivate let cellSize = CGSize(width: 100, height: 100)
    
    var phAsset: PHAsset!
    
    let reuseIdentifier = "AlbumViewCell"
    let headerReuseIdentifier = "HeaderCell"
    private var cleanupComplete = false
    
    public func performCleanup() {
        if !cleanupComplete {
            images = nil
            imageManager = nil
            delegate = nil
            collectionView = nil
            phAsset = nil
            images = nil
            videos = nil
            
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    deinit {
        performCleanup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
        setupImages()
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setupLayout() {
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 1, itemSpacing: 1, stickyHeader: true)
        
        collectionView.register(AlbumCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView.backgroundColor = UIColor.white
        
        addSubview(collectionView)
    }
    
    func setupImages() {
        
        if images != nil {
            collectionView.reloadData()
            return
        }
        
        // Never load photos Unless the user allows to access to photo album
        checkPhotoAuth()
        
        // Sorting condition
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        images = PHAsset.fetchAssets(with: .image, options: options)
        
        if images.count > 0 {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.reloadData()
        }
        
        PHPhotoLibrary.shared().register(self)
    }
    
    func getVideos() {
        // Sorting condition
        if videos != nil {
            collectionView.reloadData()
            return
        }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        videos = PHAsset.fetchAssets(with: .video, options: options)
        
        if videos.count > 0 {
            collectionView.reloadData()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    // MARK: - UICollectionViewDelegate Protocol
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? AlbumCell else {
            return UICollectionViewCell()
        }
        
        let currentTag = cell.tag + 1
        cell.tag = currentTag
        
        let asset = currentMode == .albumImage ? images[(indexPath as NSIndexPath).item] : videos[(indexPath as NSIndexPath).item]
        
        imageManager?.requestImage(for: asset, targetSize: cellSize, contentMode: .aspectFill, options: nil) {result, info in
            if cell.tag == currentTag {
                cell.updateImageAndDuration(image: result, duration: asset.duration)
            }
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images == nil ? 0 : images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let phAsset = currentMode == .albumImage ? images[(indexPath as NSIndexPath).row] : videos[(indexPath as NSIndexPath).row]
        
        let metaData = ImageMetadata(
            mediaType: phAsset.mediaType,
            pixelWidth: phAsset.pixelWidth,
            pixelHeight: phAsset.pixelHeight,
            location: phAsset.location,
            duration: phAsset.duration
        )
        
        if currentMode == .albumImage {
            DispatchQueue.global(qos: .default).async(execute: {[weak self] in
                guard let `self` = self else { return }
                
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .exact
                
                self.imageManager?.requestImage(for: phAsset, targetSize: CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight),
                                                contentMode: .aspectFill, options: options) {[weak self] result, info in
                    guard let `self` = self else { return }
                                                    
                    if !(info![PHImageResultIsDegradedKey] as! Bool) {
                        DispatchQueue.main.async(execute: {[unowned self] in
                            self.delegate?.selectedImage(image: result, metaData: metaData)
                        })
                    }
                }
            })
        } else if currentMode == .albumVideo {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .mediumQualityFormat
            
            self.delegate?.selectedVideo(video: phAsset, metaData: metaData)

        }
    }
    
    // MARK: - ScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == collectionView {
            
            self.updateCachedAssets()
        }
    }
    
    
    //MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        DispatchQueue.main.async {
            
            guard let collectionChanges = changeInstance.changeDetails(for: self.images) else {
                
                return
            }
            
            self.images = collectionChanges.fetchResultAfterChanges
            
            let collectionView = self.collectionView!
            
            if !collectionChanges.hasIncrementalChanges ||
                collectionChanges.hasMoves {
                
                collectionView.reloadData()
                
            } else {
                
                collectionView.performBatchUpdates({
                    
                    if let removedIndexes = collectionChanges.removedIndexes,
                        removedIndexes.count != 0 {
                        
                        collectionView.deleteItems(at: removedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }
                    
                    if let insertedIndexes = collectionChanges.insertedIndexes,
                        insertedIndexes.count != 0 {
                        
                        collectionView.insertItems(at: insertedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }
                    
                    if let changedIndexes = collectionChanges.changedIndexes,
                        changedIndexes.count != 0 {
                        
                        collectionView.reloadItems(at: changedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }
                    
                }, completion: nil)
            }
            
            self.resetCachedAssets()
        }
    }
}

internal extension UICollectionView {
    
    func aapl_indexPathsForElementsInRect(_ rect: CGRect) -> [IndexPath] {
        
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElements(in: rect)
        if (allLayoutAttributes?.count ?? 0) == 0 {return []}
        
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(allLayoutAttributes!.count)
        
        for layoutAttributes in allLayoutAttributes! {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        
        return indexPaths
    }
}

internal extension IndexSet {
    
    func aapl_indexPathsFromIndexesWithSection(_ section: Int) -> [IndexPath] {
        
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(self.count)
        
        (self as NSIndexSet).enumerate({idx, stop in
            
            indexPaths.append(IndexPath(item: idx, section: section))
        })
        
        return indexPaths
    }
}

private extension PulseAlbumView {
    
    // Check the status of authorization for PHPhotoLibrary
    func checkPhotoAuth() {
        
        PHPhotoLibrary.requestAuthorization {[weak self] (status) -> Void in
            guard let `self` = self else { return }
            
            switch status {
                
            case .authorized:
                
                self.imageManager = PHCachingImageManager()
                
            case .restricted, .denied:
                
                DispatchQueue.main.async(execute: {[unowned self] () -> Void in
                    
                    self.delegate?.albumViewCameraRollUnauthorized()
                })
                
            default:
                
                break
            }
        }
    }
    
    // MARK: - Asset Caching
    
    func resetCachedAssets() {
        
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRect.zero
    }
    
    func updateCachedAssets() {
        
        guard let collectionView = self.collectionView else { return }
        
        var preheatRect = collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - self.previousPreheatRect.midY)
        
        if delta > collectionView.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath]   = []
            var removedIndexPaths: [IndexPath] = []
            
            self.computeDifferenceBetweenRect(
                self.previousPreheatRect,
                andRect: preheatRect,
                removedHandler: {[weak self] removedRect in
                    guard let `self` = self else { return }
                    
                    let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(removedRect)
                    removedIndexPaths += indexPaths
                    
            }, addedHandler: {[weak self] addedRect in
                guard let `self` = self else { return }
                
                let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(addedRect)
                addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths)
            
            self.imageManager?.startCachingImages(for: assetsToStartCaching,
                                                  targetSize: cellSize,
                                                  contentMode: .aspectFill,
                                                  options: nil)
            
            self.imageManager?.stopCachingImages(for: assetsToStopCaching,
                                                 targetSize: cellSize,
                                                 contentMode: .aspectFill,
                                                 options: nil)
            
            self.previousPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(_ oldRect: CGRect, andRect newRect: CGRect, removedHandler: (CGRect)->Void, addedHandler: (CGRect)->Void) {
        
        if newRect.intersects(oldRect) {
            
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            
            if newMaxY > oldMaxY {
                
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            
            if oldMinY > newMinY {
                
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            
            if newMaxY < oldMaxY {
                
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            
            if oldMinY < newMinY {
                
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
            
        } else {
            
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset] {
        
        if indexPaths.count == 0 { return [] }
        
        var assets: [PHAsset] = []
        
        assets.reserveCapacity(indexPaths.count)
        
        for indexPath in indexPaths {
            
            let asset = currentMode == .albumImage ? self.images[(indexPath as NSIndexPath).item] : self.videos[(indexPath as NSIndexPath).item]
            assets.append(asset)
        }
        
        return assets
    }
}

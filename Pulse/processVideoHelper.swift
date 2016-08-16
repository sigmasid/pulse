//
//  processVideoHelper.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import Photos

func processVideo(videoURL : NSURL, completion: (result: NSURL?, thumbnail : UIImage?, error : NSError?) -> Void) {
    // Edit video
    let sourceAsset = AVURLAsset(URL: videoURL, options: nil)
    let composition : AVMutableComposition = AVMutableComposition()
    let sourceDuration = CMTimeRangeMake(kCMTimeZero, sourceAsset.duration)
    
    let compositionVideoTrack : AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
    let compositionAudioTrack : AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
    let clipVideoTrack : AVAssetTrack = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
    let clipAudioTrack : AVAssetTrack = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)[0] as AVAssetTrack
    
    let renderWidth = clipVideoTrack.naturalSize.width
    let renderHeight = clipVideoTrack.naturalSize.height
    
    let insertTime = kCMTimeZero
    let endTime = sourceAsset.duration
    
    // Append tracks
    do {
        try compositionVideoTrack.insertTimeRange(sourceDuration, ofTrack: clipVideoTrack, atTime: kCMTimeZero)
        try compositionAudioTrack.insertTimeRange(sourceDuration, ofTrack: clipAudioTrack, atTime: kCMTimeZero)
    } catch _ {}
    
    let themeVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition(propertiesOfAsset: sourceAsset)
    
    // Create AVMutableVideoCompositionInstruction
    let mainInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = sourceDuration
    
    // Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    let videolayerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
    videolayerInstruction.setTransform(clipVideoTrack.preferredTransform, atTime: insertTime)
    videolayerInstruction.setOpacity(0.0, atTime: endTime)
    
    // Add instructions
    mainInstruction.layerInstructions = NSArray(array: [videolayerInstruction]) as! [AVVideoCompositionLayerInstruction]
    
    themeVideoComposition.renderScale = 1.0
    themeVideoComposition.renderSize = CGSizeMake(renderHeight, renderWidth)
    themeVideoComposition.frameDuration = CMTimeMake(1, 30)
    themeVideoComposition.instructions = NSArray(array: [mainInstruction]) as! [AVVideoCompositionInstructionProtocol]
    
    // 2. set parent layer and video layer
    
    let parentLayer = CALayer()
    let videoLayer = CALayer()
    parentLayer.frame =  CGRect(x: 0, y: 0, width: renderHeight, height: renderWidth)
    videoLayer.frame =  CGRect(x: 0, y: 0, width: renderHeight, height: renderWidth)
    parentLayer.addSublayer(videoLayer)
    
    parentLayer.contentsScale = UIScreen.mainScreen().scale
    
    // 3. make animation
    
    themeVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
    
    // Save the video to the app directory so we can play it later
    let outputUrl = tempFileURL()
    
    // Remove the file if it already exists (merger does not overwrite)
    let fileManager = NSFileManager.defaultManager()
    do {
        try fileManager.removeItemAtURL(outputUrl)
    } catch _ {
        
    }
    
    // Export the video
    let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)
    let _thumbnail = thumbnailForVideoAtURL(composition)
    
    exporter!.outputURL = outputUrl
    exporter!.videoComposition = themeVideoComposition
    exporter!.outputFileType = AVFileTypeQuickTimeMovie
    exporter!.shouldOptimizeForNetworkUse = true
    exporter!.exportAsynchronouslyWithCompletionHandler({
        switch exporter!.status {
        case  AVAssetExportSessionStatus.Failed:
            let userInfo = [ NSLocalizedDescriptionKey : "export failed" ]
            completion(result: nil, thumbnail: nil, error: NSError.init(domain: "Failed", code: 0, userInfo: userInfo))
        case AVAssetExportSessionStatus.Cancelled:
            let userInfo = [ NSLocalizedDescriptionKey : "export cancelled" ]
            completion(result: nil, thumbnail: nil, error: NSError.init(domain: "Cancelled", code: 0, userInfo: userInfo))
        case AVAssetExportSessionStatus.Completed:
            completion(result: exporter!.outputURL!, thumbnail: _thumbnail, error: nil)
        default:
            let userInfo = [ NSLocalizedDescriptionKey : "unknown error occured" ]
            completion(result: nil, thumbnail: nil, error: NSError.init(domain: "Unknown", code: 0, userInfo: userInfo))
        }
    })
}

private func thumbnailForVideoAtURL(asset: AVAsset) -> UIImage? {
    
    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
    assetImageGenerator.appliesPreferredTrackTransform = true
    
    var time = asset.duration
    time.value = min(time.value, 2)
    
    do {
        let imageRef = try assetImageGenerator.copyCGImageAtTime(time, actualTime: nil)
        let image = GlobalFunctions.fixOrientation(UIImage(CGImage: imageRef, scale: 1.0, orientation: .Right))
        return image
    } catch {
        return nil
    }
}

func compressVideo(inputURL: NSURL, completion: (result: NSURL?, thumbnail : UIImage?, error : NSError?) -> Void) {
    let outputURL = tempFileURL()
    
    let urlAsset = AVURLAsset(URL: inputURL, options: nil)
    let _thumbnail = thumbnailForVideoAtURL(urlAsset)

    if let exporter = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
        exporter.outputURL = outputURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronouslyWithCompletionHandler { () -> Void in
            switch exporter.status {
            case  AVAssetExportSessionStatus.Failed:
                let userInfo = [ NSLocalizedDescriptionKey : "export failed" ]
                completion(result: nil, thumbnail: nil, error: NSError.init(domain: "Failed", code: 0, userInfo: userInfo))
            case AVAssetExportSessionStatus.Cancelled:
                let userInfo = [ NSLocalizedDescriptionKey : "export cancelled" ]
                completion(result: nil, thumbnail: nil, error: NSError.init(domain: "Cancelled", code: 0, userInfo: userInfo))
            case AVAssetExportSessionStatus.Completed:
                completion(result: exporter.outputURL!, thumbnail: _thumbnail, error: nil)
            default:
                let userInfo = [ NSLocalizedDescriptionKey : "unknown error occured" ]
                completion(result: nil, thumbnail: nil, error: NSError.init(domain: "Unknown", code: 0, userInfo: userInfo))
            }
        }
    }
}

private func tempFileURL() -> NSURL {
    let saveFileName = "/pulse-\(Int(NSDate().timeIntervalSince1970)).mp4"
    
    let paths = NSSearchPathForDirectoriesInDomains(
        NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    let documentsDirectory: AnyObject = paths[0]
    let dataPath = documentsDirectory.stringByAppendingPathComponent(saveFileName)
    let outputUrl = NSURL(fileURLWithPath: dataPath)
    
    return outputUrl
}



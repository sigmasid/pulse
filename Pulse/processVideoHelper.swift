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

func processVideo(_ videoURL : URL, completion: @escaping (_ result: URL?, _ thumbnail : UIImage?, _ error : NSError?) -> Void) {
    // Edit video
    let sourceAsset = AVURLAsset(url: videoURL, options: nil)
    let composition : AVMutableComposition = AVMutableComposition()
    let sourceDuration = CMTimeRangeMake(kCMTimeZero, sourceAsset.duration)
    
    let compositionVideoTrack : AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
    let compositionAudioTrack : AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
    let clipVideoTrack : AVAssetTrack = sourceAsset.tracks(withMediaType: AVMediaTypeVideo)[0] as AVAssetTrack
    let clipAudioTrack : AVAssetTrack = sourceAsset.tracks(withMediaType: AVMediaTypeAudio)[0] as AVAssetTrack
    
    let renderWidth = clipVideoTrack.naturalSize.width
    let renderHeight = clipVideoTrack.naturalSize.height
    
    let insertTime = kCMTimeZero
    let endTime = sourceAsset.duration
    
    // Append tracks
    do {
        try compositionVideoTrack.insertTimeRange(sourceDuration, of: clipVideoTrack, at: kCMTimeZero)
        try compositionAudioTrack.insertTimeRange(sourceDuration, of: clipAudioTrack, at: kCMTimeZero)
    } catch _ {}
    
    let themeVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition(propertiesOf: sourceAsset)
    
    // Create AVMutableVideoCompositionInstruction
    let mainInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = sourceDuration
    
    // Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    let videolayerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
    videolayerInstruction.setTransform(clipVideoTrack.preferredTransform, at: insertTime)
    videolayerInstruction.setOpacity(0.0, at: endTime)
    
    // Add instructions
    mainInstruction.layerInstructions = NSArray(array: [videolayerInstruction]) as! [AVVideoCompositionLayerInstruction]
    
    themeVideoComposition.renderScale = 1.0
    themeVideoComposition.renderSize = CGSize(width: renderHeight, height: renderWidth)
    themeVideoComposition.frameDuration = CMTimeMake(1, 30)
    themeVideoComposition.instructions = NSArray(array: [mainInstruction]) as! [AVVideoCompositionInstructionProtocol]
    
    // 2. set parent layer and video layer
    
    let parentLayer = CALayer()
    let videoLayer = CALayer()
    parentLayer.frame =  CGRect(x: 0, y: 0, width: renderHeight, height: renderWidth)
    videoLayer.frame =  CGRect(x: 0, y: 0, width: renderHeight, height: renderWidth)
    parentLayer.addSublayer(videoLayer)
    
    parentLayer.contentsScale = UIScreen.main.scale
    
    // 3. make animation
    
    themeVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    
    // Save the video to the app directory so we can play it later
    let outputUrl = tempFileURL()
    
    // Remove the file if it already exists (merger does not overwrite)
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(at: outputUrl)
    } catch _ {
        
    }
    
    // Export the video
    let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)
    let _thumbnail = thumbnailForVideoAtURL(composition, orientation: .right)
    
    exporter!.outputURL = outputUrl
    exporter!.videoComposition = themeVideoComposition
    exporter!.outputFileType = AVFileTypeQuickTimeMovie
    exporter!.shouldOptimizeForNetworkUse = true
    exporter!.exportAsynchronously(completionHandler: {
        switch exporter!.status {
        case  AVAssetExportSessionStatus.failed:
            let userInfo = [ NSLocalizedDescriptionKey : "export failed" ]
            completion(nil, nil, NSError.init(domain: "Failed", code: 0, userInfo: userInfo))
        case AVAssetExportSessionStatus.cancelled:
            let userInfo = [ NSLocalizedDescriptionKey : "export cancelled" ]
            completion(nil, nil, NSError.init(domain: "Cancelled", code: 0, userInfo: userInfo))
        case AVAssetExportSessionStatus.completed:
            completion(exporter!.outputURL!, _thumbnail, nil)
        default:
            let userInfo = [ NSLocalizedDescriptionKey : "unknown error occured" ]
            completion(nil, nil, NSError.init(domain: "Unknown", code: 0, userInfo: userInfo))
        }
    })
}

func thumbnailForVideoAtURL(_ asset: AVAsset, orientation: UIImageOrientation) -> UIImage? {
    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
    assetImageGenerator.appliesPreferredTrackTransform = true
    
    var time = asset.duration
    time.value = min(time.value, 2)
    
    do {
        let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
        let image = UIImage(cgImage: imageRef, scale: 1.0, orientation: orientation)
        return image
    } catch {
        return nil
    }
}

func compressVideo(_ inputURL: URL, completion: @escaping (_ result: URL?, _ thumbnail : UIImage?, _ error : NSError?) -> Void) {
    let outputURL = tempFileURL()
    let urlAsset = AVURLAsset(url: inputURL, options: nil)
    let _thumbnail = thumbnailForVideoAtURL(urlAsset, orientation: .up)

    if let exporter = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
        exporter.outputURL = outputURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronously { () -> Void in
            switch exporter.status {
            case  AVAssetExportSessionStatus.failed:
                let userInfo = [ NSLocalizedDescriptionKey : "export failed" ]
                completion(nil, nil, NSError.init(domain: "Failed", code: 0, userInfo: userInfo))
            case AVAssetExportSessionStatus.cancelled:
                let userInfo = [ NSLocalizedDescriptionKey : "export cancelled" ]
                completion(nil, nil, NSError.init(domain: "Cancelled", code: 0, userInfo: userInfo))
            case AVAssetExportSessionStatus.completed:
                completion(exporter.outputURL!, _thumbnail, nil)
            default:
                let userInfo = [ NSLocalizedDescriptionKey : "unknown error occured" ]
                completion(nil, nil, NSError.init(domain: "Unknown", code: 0, userInfo: userInfo))
            }
        }
    } else {
        let userInfo = [ NSLocalizedDescriptionKey : "unknown error occured" ]
        completion(nil, nil, NSError.init(domain: "Unknown", code: 0, userInfo: userInfo))
    }
}

private func tempFileURL() -> URL {
    let saveFileName = "/pulse-\(Int(Date().timeIntervalSince1970)).mp4"
    
    let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                    FileManager.SearchPathDomainMask.userDomainMask, true)
    let documentsDirectory: AnyObject = paths[0] as AnyObject
    let dataPath = documentsDirectory.appending(saveFileName)
    let outputUrl = URL(fileURLWithPath: dataPath)
    
    return outputUrl
}



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

func processVideo(videoURL : NSURL, location: String?, aQuestion : Question?, completion: (result: NSURL) -> Void) {
    let saveFileName = "/pulse-\(Int(NSDate().timeIntervalSince1970)).mp4"
    
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
    
    // Add text
    let coverAttributeLabel = [ NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 36)!, NSForegroundColorAttributeName: UIColor.whiteColor()]
    
    let userNameLabelLayer = CATextLayer()
    let userLocationLabelLayer = CATextLayer()
    
    if let userScreenName = User.currentUser.screenName  {
        print("user has username")
        userNameLabelLayer.string = NSMutableAttributedString(string: userScreenName, attributes: coverAttributeLabel)
        
        let size = userScreenName.sizeWithAttributes(coverAttributeLabel)
        
        //        userNameLabelLayer.backgroundColor = UIColor.whiteColor().CGColor
        userNameLabelLayer.opacity = 0.7
        userNameLabelLayer.frame = CGRectMake(10, 10, ceil(size.width), ceil(size.height))
    }
    
    if let userName = User.currentUser.name {
        print("user has name")
        userNameLabelLayer.string = NSMutableAttributedString(string: userName, attributes: coverAttributeLabel)
        let size = userName.sizeWithAttributes(coverAttributeLabel)
        userNameLabelLayer.opacity = 0.7
        userNameLabelLayer.frame = CGRectMake(10, 10, ceil(size.width), ceil(size.height))
    }
    
    if let userLocation = location {
        print("user has location \(userLocation)")
        let userLocation = NSMutableAttributedString(string: userLocation, attributes: coverAttributeLabel)
        let size = userLocation.string.sizeWithAttributes(coverAttributeLabel)
        
        userLocationLabelLayer.string = userLocation
        //        userLocationLabelLayer.backgroundColor = UIColor.whiteColor().CGColor
        userLocationLabelLayer.opacity = 0.7
        userLocationLabelLayer.frame = CGRectMake(10, 40, size.width, size.height)
    }
    
    // 2. set parent layer and video layer
    
    let parentLayer = CALayer()
    let videoLayer = CALayer()
    parentLayer.frame =  CGRect(x: 0, y: 0, width: renderHeight, height: renderWidth)
    videoLayer.frame =  CGRect(x: 0, y: 0, width: renderHeight, height: renderWidth)
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(userNameLabelLayer)
    parentLayer.addSublayer(userLocationLabelLayer)
    
    parentLayer.contentsScale = UIScreen.mainScreen().scale
    
    // 3. make animation
    
    themeVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
    
    // Save the video to the app directory so we can play it later
    let paths = NSSearchPathForDirectoriesInDomains(
        NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    let documentsDirectory: AnyObject = paths[0]
    let dataPath = documentsDirectory.stringByAppendingPathComponent(saveFileName)
    let outputUrl = NSURL(fileURLWithPath: dataPath)
    
    // Remove the file if it already exists (merger does not overwrite)
    let fileManager = NSFileManager.defaultManager()
    do {
        try fileManager.removeItemAtURL(outputUrl)
    } catch _ {
        
    }
    
    // Export the video
    let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
    
    exporter!.outputURL = outputUrl
    exporter!.videoComposition = themeVideoComposition
    exporter!.outputFileType = AVFileTypeQuickTimeMovie
    exporter!.shouldOptimizeForNetworkUse = true
    exporter!.exportAsynchronouslyWithCompletionHandler({
        switch exporter!.status {
        case  AVAssetExportSessionStatus.Failed:
            print("failed \(exporter!.error)")
        case AVAssetExportSessionStatus.Cancelled:
            print("cancelled \(exporter!.error)")
        case AVAssetExportSessionStatus.Completed:
            print("complete \(exporter!.outputURL)")
            completion(result: exporter!.outputURL!)
        default: print("somehting else")
        }
    })
}

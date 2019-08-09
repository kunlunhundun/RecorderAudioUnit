//
//  RecordManager.m
//  EAudioKit
//
//  Created by zhou on 15/10/26.
//  Copyright © 2015年 rcsing. All rights reserved.
//
#import "AVAssertMixer.h"

#import "EAudioMisc.h"
#import <AudioToolbox/AudioConverter.h>

#define ADTS_HEADER_LENGTH  7
#define AAC_FRAMES_PER_PACKET 1024

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface AVAssertMixer()
{
    AVAssetExportSession* _assetExport;
    AVMutableComposition* _mixComposition;
    AVMutableVideoComposition * _avMutableVideoComposition;
  //  AVMutableCompositionTrack *_compositionAudioTrack;
   // AVAssetTrack* _audioTrack;
    
}

@end

@implementation AVAssertMixer

-(instancetype)init
{
    self = [super init];
    
    _mixComposition = [AVMutableComposition composition];
    
    return self;
}

-(void)addVideoTrack:(NSString*)videoFilePath offset:(CGFloat)offset
{

    DEBUG_LOG(@"addVideoTrack:%@",videoFilePath);
    NSInteger count = offset * 30;
    CMTime startTime = CMTimeMake(count, 30);
    
    NSURL *videoUrl = [NSURL fileURLWithPath:videoFilePath];
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    if (count > 0) {
       videoTimeRange = CMTimeRangeMake(startTime,videoAsset.duration);
    }
    DEBUG_LOG(@"addVideoTrackcount:%d, startTime:%.3f",(int)count,CMTimeGetSeconds(startTime));
    
    NSString* mediaType = AVMediaTypeVideo;
    NSArray<AVAssetTrack *> * trackers = [videoAsset tracksWithMediaType:mediaType];
    if (trackers == nil || trackers.count <= 0){return;}
    
    AVAssetTrack* videoTrack = [trackers objectAtIndex:0];
   
    AVMutableCompositionTrack *compositionVideoTrack = [_mixComposition addMutableTrackWithMediaType:mediaType
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
    compositionVideoTrack.preferredTransform = videoTrack.preferredTransform;
    
    NSError* error = nil;
    [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:videoTrack atTime:kCMTimeZero error:&error];
}



-(void)addVideoTrackWithWaterMask:(NSString*)videoFilePath waterTitle:(NSString*)waterTitle{
    
    
    NSURL *videoUrl = [NSURL fileURLWithPath:videoFilePath];
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    
    NSString* mediaType = AVMediaTypeVideo;
    NSArray<AVAssetTrack *> * trackers = [videoAsset tracksWithMediaType:mediaType];
    if (trackers == nil || trackers.count <= 0){return;}
    
    AVAssetTrack* videoTrack = [trackers objectAtIndex:0];
    
    
    
    CGSize videoSize = videoTrack.naturalSize;

    NSLog(@"videoSize.width:%.1f, height:%.1f",videoSize.width,videoSize.height);
    
    AVMutableCompositionTrack *avMutableCompositionTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;
    // 这块是裁剪,rangtime .前面的是开始时间,后面是裁剪多长
    [avMutableCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration)
                                       ofTrack:videoTrack
                                        atTime:kCMTimeZero
                                         error:&error];
    
    CALayer *animatedTitleLayer = [self buildAnimatedTitleLayerForSize:CGSizeMake(videoSize.width, videoSize.height) waterTitle:waterTitle];
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:animatedTitleLayer];
    
    
    
    AVMutableVideoCompositionInstruction *avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];

    [avMutableVideoCompositionInstruction setTimeRange:videoTimeRange];
    
    AVMutableVideoCompositionLayerInstruction *avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    
    avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
    
    
    AVMutableVideoComposition *avMutableVideoComposition = [AVMutableVideoComposition videoComposition] ;
//    avMutableVideoComposition.renderSize = CGSizeMake(480.0f, 640.0f);
//    avMutableVideoComposition.frameDuration = CMTimeMake(1, 30);
//    avMutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    
    avMutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    avMutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    avMutableVideoComposition.renderSize = videoSize;
    avMutableVideoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
    
    _avMutableVideoComposition = avMutableVideoComposition;
    
}



-(void)addAudioTrack:(NSString*)audioFilePath
{
    DEBUG_LOG(@"addAudioTrack:%@",audioFilePath);
    NSURL *audioUrl = [NSURL fileURLWithPath:audioFilePath];
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    
    NSString* mediaType = AVMediaTypeAudio;
    NSArray<AVAssetTrack *> * trackers = [audioAsset tracksWithMediaType:mediaType];
    if (trackers == nil || trackers.count <= 0){return;}
    
    AVAssetTrack* audioTrack = [trackers objectAtIndex:0];
    AVMutableCompositionTrack *compositionAudioTrack = [_mixComposition addMutableTrackWithMediaType:mediaType
                                                                                    preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError* error = nil;
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    
    [compositionAudioTrack insertTimeRange:audioTimeRange ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
}



+ (void)captureSongAction:(NSString*)audioFilePath outputFilePath:(NSString*)outputFilePath startTime:(NSInteger)startTime endTime:(NSInteger)endTime captureSongCompeleteBlock:(CaptureSongCompeleteBlock)captureSongBlock
{

    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    }

    NSURL *audioUrl = [NSURL fileURLWithPath:audioFilePath];
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    
    NSString* mediaType = AVMediaTypeAudio;
    NSArray<AVAssetTrack *> * trackers = [audioAsset tracksWithMediaType:mediaType];
    if (trackers == nil || trackers.count <= 0){
        captureSongBlock(false);
        return;
    }
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:audioAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:audioAsset presetName:AVAssetExportPresetAppleM4A];
      

        CMTime startCmTime = CMTimeMake(startTime, 1);
        CMTime stopTime = CMTimeMake(endTime, 1);
        CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startCmTime, stopTime);
        
        NSURL *furl = [NSURL fileURLWithPath:outputFilePath];
        exportSession.outputURL = furl;
        exportSession.outputFileType = AVFileTypeAppleM4A;
        exportSession.timeRange = exportTimeRange; // 截取时间
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{

                switch ([exportSession status]) {
                    case AVAssetExportSessionStatusFailed:
                        captureSongBlock(false);
                        NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                        break;
                    case AVAssetExportSessionStatusCancelled:
                        captureSongBlock(false);
                        NSLog(@"Export canceled");
                        break;
                    default:
                        NSLog(@"保存成功");
                }
                BOOL isCompleted = (AVAssetExportSessionStatusCompleted == exportSession.status);
                if(isCompleted)
                {
                    captureSongBlock(true);
                    
                    NSFileManager* fileMgr = [NSFileManager defaultManager];
                    NSDictionary<NSString *, id>* dict = [fileMgr attributesOfItemAtPath:outputFilePath error:NULL];
                    if(dict != nil){
                        float size = [dict fileSize] / 1024.0;
                        if(size > 1024 ){
                            NSLog(@"captureM4a end,%@,size:%.2fMb",outputFilePath,size/1024);
                        }else{
                            NSLog(@"captureM4a end,%@,size:%.2fKb",outputFilePath,size);
                        }
                    }
                }
            });
            
        }];
    }
    
}



-(void)startMixMp4:(NSString*)outputFilePath whenFinish:(void (^)(BOOL isCompleted))block
{
    DEBUG_LOG(@"startMixMp4:%@",outputFilePath);
    
    
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:_mixComposition presetName:AVAssetExportPresetPassthrough];//AVAssetExportPresetMediumQuality
    assetExport.outputFileType = AVFileTypeMPEG4;//AVFileTypeQuickTimeMovie
    assetExport.outputURL = outputFileUrl;
    
    _assetExport = assetExport;
    
    
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             
             DEBUG_LOG(@"exportSessionStatus:%ld,err:%@",(long)assetExport.status,assetExport.error);
             BOOL isCompleted = (AVAssetExportSessionStatusCompleted == assetExport.status);
#if DEBUG
             if(isCompleted)
             {
                 NSFileManager* fileMgr = [NSFileManager defaultManager];
                 NSDictionary<NSString *, id>* dict = [fileMgr attributesOfItemAtPath:outputFilePath error:NULL];
                 if(dict != nil){
                     float size = [dict fileSize] / 1024.0;
                     if(size > 1024 ){
                         NSLog(@"startMixMp4 end,%@,size:%.2fMb",outputFilePath,size/1024);
                     }else{
                         NSLog(@"startMixMp4 end,%@,size:%.2fKb",outputFilePath,size);
                     }
                 }
             }
#endif
             block(isCompleted);
             
         });
     }
     ];
}




-(void)startShortMVMixMp4:(NSString*)outputFilePath whenFinish:(void (^)(BOOL isCompleted))block
{
    DEBUG_LOG(@"startShortMVMixMp4:%@",outputFilePath);
    
    
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    
    AVAssetExportSession *avAssetExportSession = [[AVAssetExportSession alloc] initWithAsset:_mixComposition presetName:AVAssetExportPreset640x480];
    [avAssetExportSession setVideoComposition:_avMutableVideoComposition];
    [avAssetExportSession setOutputURL:outputFileUrl];
    [avAssetExportSession setOutputFileType:AVFileTypeMPEG4];
 //   [avAssetExportSession setShouldOptimizeForNetworkUse:YES];
    
//    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:_mixComposition presetName:AVAssetExportPresetPassthrough];//AVAssetExportPresetMediumQuality
//    assetExport.outputFileType = AVFileTypeMPEG4;//AVFileTypeQuickTimeMovie
//    assetExport.outputURL = outputFileUrl;
    
    _assetExport = avAssetExportSession;
    [avAssetExportSession exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             
             DEBUG_LOG(@"exportSessionStatus:%ld,err:%@",(long)avAssetExportSession.status,avAssetExportSession.error);
             BOOL isCompleted = (AVAssetExportSessionStatusCompleted == avAssetExportSession.status);
#if DEBUG
             if(isCompleted)
             {
                 NSFileManager* fileMgr = [NSFileManager defaultManager];
                 NSDictionary<NSString *, id>* dict = [fileMgr attributesOfItemAtPath:outputFilePath error:NULL];
                 if(dict != nil){
                     float size = [dict fileSize] / 1024.0;
                     if(size > 1024 ){
                         NSLog(@"startShortMVMixMp4 end,%@,size:%.2fMb",outputFilePath,size/1024);
                     }else{
                         NSLog(@"startShortMVMixMp4 end,%@,size:%.2fKb",outputFilePath,size);
                     }
                 }
             }
#endif
             block(isCompleted);
             
         });
     }
     ];
}


- (CALayer *)buildAnimatedTitleLayerForSize:(CGSize)videoSize waterTitle:(NSString*)waterTitle
{
    // 视频的显示大小
    CGSize dataLayerSize = CGSizeMake(videoSize.width, videoSize.height);
    // Create a layer for the overall title animation.
    CALayer *animatedTitleLayer = [CALayer layer];
    // 由于旋转过了,所以高与宽互相转换了,原来 480*640 由于旋转 成了640*480
    // 他们的起点还是左下角
    //animatedTitleLayer.frame = CGRectMake(0.0f, 0, dataLayerSize.width, dataLayerSize.height);
    animatedTitleLayer.frame = CGRectMake(0.0f, videoSize.width-dataLayerSize.height, dataLayerSize.width, dataLayerSize.height);
    animatedTitleLayer.backgroundColor = [UIColor clearColor].CGColor;
    // 水印
    UIImage *waterMarkImage = [UIImage imageNamed:@"waterMark"];
    CALayer *waterMarkLayer = [CALayer layer];
    waterMarkLayer.contents = (id)waterMarkImage.CGImage ;
    waterMarkLayer.frame = CGRectMake(dataLayerSize.width-waterMarkImage.size.width-15.0f-150, dataLayerSize.height-waterMarkImage.size.height-15.0f+100, waterMarkImage.size.width, waterMarkImage.size.height);
   //  waterMarkLayer.frame = CGRectMake(dataLayerSize.width-waterMarkImage.size.width-15.0f ,  20.0f+15.0f, waterMarkImage.size.width, waterMarkImage.size.height);
    waterMarkLayer.opacity = 0.6f;
    
    NSLog(@"waterMarkLayer.frame:%@ \n",(NSStringFromCGRect(waterMarkLayer.frame)));
    
    // 文字
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = waterTitle;
   // textLayer.font = @"Helvetica";
    textLayer.fontSize = 20.0f;
    textLayer.shadowOpacity = 0.6f ;
    textLayer.backgroundColor = [UIColor clearColor].CGColor ;
    textLayer.foregroundColor = UIColorFromRGB(0x848587).CGColor;//[UIColor redColor].CGColor ;  848587
    textLayer.frame = CGRectMake(waterMarkLayer.frame.origin.x + waterMarkLayer.frame.size.width + 10 , dataLayerSize.height-waterMarkImage.size.height-15.0f+100, 100, 22.0f);
    [animatedTitleLayer addSublayer:waterMarkLayer];
    [animatedTitleLayer addSublayer:textLayer];
    
    return animatedTitleLayer;
}



@end

//
//  RecordManager.h
//  EAudioKit
//
//  Created by zhou on 15/10/26.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef void (^CaptureSongCompeleteBlock)(BOOL isSuccess);

@interface AVAssertMixer : NSObject

-(void)addVideoTrack:(NSString*)videoFilePath offset:(CGFloat)offset;

-(void)addAudioTrack:(NSString*)audioFilePath;

-(void)startMixMp4:(NSString*)outputFilePath whenFinish:(void (^)(BOOL isCompleted))block;

-(void)addVideoTrackWithWaterMask:(NSString*)videoFilePath waterTitle:(NSString*)waterTitle;

-(void)startShortMVMixMp4:(NSString*)outputFilePath whenFinish:(void (^)(BOOL isCompleted))block;

+(void)captureSongAction:(NSString*)audioFilePath outputFilePath:(NSString*)outputFilePath startTime:(NSInteger)startTime endTime:(NSInteger)endTime captureSongCompeleteBlock:(CaptureSongCompeleteBlock)captureSongBlock;


@end

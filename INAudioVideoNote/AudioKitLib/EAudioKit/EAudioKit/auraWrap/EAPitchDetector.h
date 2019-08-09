//
//  EAPitchDetector.h
//  EAudioKit
//
//  Created by cybercall on 15/7/28.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface EAPitchDetector : NSObject
@property (nonatomic,readonly) float frequency;

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription)asbd;

-(void)processPitch:(const AudioTimeStamp*)inTimeStamp
        inNumberFrames:(UInt32)inNumberFrames
        AudioBufferList:(AudioBufferList*)ioData;
@end

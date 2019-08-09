//
//  EAMicrophone.h
//  AudioTest
//
//  Created by cybercall on 15/7/14.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface EAMicrophone : NSObject

-(instancetype)init:(AudioStreamBasicDescription) audioFormat;

-(void)start;

-(void)stop;

//将mic音频数据保存到file
-(void)record:(NSString*)file;

-(AudioStreamBasicDescription)getOutputFormat;

//读取mic数据到ioData
-(UInt32)renderAudioToBuffer:(const AudioTimeStamp *)inTimeStamp
                inNumberFrames:(UInt32)inNumberFrames
               AudioBufferList:(AudioBufferList*)ioData;

@end

//
//  EAAudioBufferAsyReader.h
//  EAudioKit
//
//  Created by cybercall on 15/8/10.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EAudioFile.h"

@interface EAAudioPitch : NSObject<EAudioFeeder>

@property (nonatomic,copy)             void(^onReady)();

-(instancetype)initWithAudioPath:(NSTimeInterval)bufferTime
                      audioFormat:(AudioStreamBasicDescription)format
                        audioFile:(NSString*)path;

-(instancetype)initWithAudioFile:(NSTimeInterval)bufferTime
                      audioFormat:(AudioStreamBasicDescription)format
                        audioFile:(EAudioFile*)audioFile;

-(void)setPitch:(int)pitch;

/*EAudioFeeder begin*/

-(int)feedBufferList:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount;

-(BOOL)seekToFrame:(float)second;

-(void)setDelay:(float)second;

-(void)close;
/*EAudioFeeder end*/

@end

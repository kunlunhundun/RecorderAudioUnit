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

@interface EAAudioPitchSyn : NSObject<EAudioFeeder>

@property (nonatomic,copy)             void(^onReady)();

-(instancetype)initWithAudioPath:(AudioStreamBasicDescription)format
                        audioFile:(NSString*)path;

-(instancetype)initWithAudioFile:(AudioStreamBasicDescription)format
                        audioFile:(EAudioFile*)audioFile;

-(void)setPitch:(int)pitch;

/*EAudioFeeder begin*/

-(int)feedBufferList:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount;

-(BOOL)seekToFrame:(float)second;

-(void)setDelay:(float)second;

-(void)close;
/*EAudioFeeder end*/

@end

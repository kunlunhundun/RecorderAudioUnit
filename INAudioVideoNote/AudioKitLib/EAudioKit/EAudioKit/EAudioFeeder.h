//
//  EAudioGraph.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////EAudioFeeder//////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

@protocol EAudioFeeder <NSObject>

-(int)feedBufferList:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount;

-(BOOL)seekToFrame:(float)second;

-(void)setDelay:(float)second;

-(void)close;

@end



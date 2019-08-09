//
//  AEAudioFileNode.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EAudioGraph.h"

////////////////////////////////////////////////////////////////
////////////////////EAudioRenderBufferRecorder//////////////////////////
////////////////////////////////////////////////////////////////
#pragma mark --EAudioRenderBufferRecorder --
@interface EAudioRenderBufferRecorder : NSObject

-(instancetype)init;

-(BOOL)setup:(NSString*)file AudioStreamFormat:(AudioStreamBasicDescription)audioStreamFormat enableSynWrite:(BOOL)enableSynWrite;
-(OSStatus)pushAudioBuffer:(AudioUnitRenderActionFlags*)ioActionFlags
        AudioTimeStamp:(const AudioTimeStamp *)inTimeStamp
           inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames
       AudioBufferList:(AudioBufferList*)ioData;

-(void)close;
@end


////////////////////////////////////////////////////////////////
////////////////////EAudioNodeRecorder//////////////////////////
////////////////////////////////////////////////////////////////
#pragma mark --EAudioNodeRecorder --
@interface EAudioNodeRecorder : NSObject

-(BOOL)attachAudioNode:(AudioUnit)audioUnit outputPath:(NSString*)file enableSynWrite:(BOOL)enableSynWrite;
-(void)detach;

@end

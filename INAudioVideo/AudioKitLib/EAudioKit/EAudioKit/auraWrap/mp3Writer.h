//
//  mp3Writer.h
//  EAudioKit
//
//  Created by cybercall on 15/7/29.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface mp3Writer : NSObject

-(BOOL)config:(NSString*)path audioSourceFormat:(AudioStreamBasicDescription)format;

-(OSStatus)pushAudioBuffer:(UInt32)inNumberFrames AudioBufferList:(AudioBufferList*)ioData;

-(void)close;


@end

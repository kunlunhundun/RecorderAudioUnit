//
//  auraWrap.h
//  AudioTest
//
//  Created by cybercall on 15/7/16.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "auraConfig.h"


@interface auraReverb : NSObject
@property (nonatomic,assign) AuraReverbPresent reverbPresent;

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription) audioSourceFormat;

-(void)process:(AudioBufferList*)ioData;

-(void)setReverbOption:(AuraReverbOption)opt Value:(float)v;

-(float)getReverbOption:(AuraReverbOption)opt;

-(void)setReverbOpts:(float[AuraReverbOption_MAX])opts;

@end

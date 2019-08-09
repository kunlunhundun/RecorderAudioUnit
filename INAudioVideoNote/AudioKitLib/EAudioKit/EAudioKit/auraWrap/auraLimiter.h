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


@interface auraLimiter : NSObject

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription) audioSourceFormat;

-(void)process:(AudioBufferList*)ioData;


@end

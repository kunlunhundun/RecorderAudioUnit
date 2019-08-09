//
//  auraWrap.h
//  AudioTest
//
//  Created by cybercall on 15/7/16.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioConfig.h"


static EAudioConfig* g_ins = nil;

@implementation EAudioConfig

-(instancetype)init
{
    self = [super init];
    
    _aacBitRate     = 128000;

    return self;
}

+(instancetype)defaultConfig
{
    
    if (g_ins == nil) {
        g_ins = [[EAudioConfig alloc] init];
    }
    return g_ins;
}

@end



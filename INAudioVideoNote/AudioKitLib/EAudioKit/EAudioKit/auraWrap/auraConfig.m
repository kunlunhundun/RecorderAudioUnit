//
//  auraWrap.h
//  AudioTest
//
//  Created by cybercall on 15/7/16.
//  Copyright © 2015年 rcshow. All rights reserved.
//
#import "platform.h"
#import "auraConfig.h"
#import "mp3.h"
#import "aura.h"

static auraConfig* g_ins = nil;

@implementation auraConfig

-(instancetype)init
{
    self = [super init];
    
    _mp3Bitrate     = 128;
    _mp3EncodeType  = mp3::EncoderType::LAME_ENCODER;//HELIX_ENCODER
    _mp3Quality     = mp3::Qualities::QUALITY_NEAR_BEST;//QUALITY_GOOD,QUALITY_BEST;
    _reverbType     = aura::ReverbType::SIMPLE_TANK;
   // _reverbType = aura::ReverbType::OPENAL;

    _freqDetectDuration = 16.0 / 1000;
    return self;
}

+(instancetype)defaultConfig
{
    
    if (g_ins == nil) {
        g_ins = [[auraConfig alloc] init];
    }
    return g_ins;
}

@end



//
//  auraWrap.h
//  AudioTest
//
//  Created by cybercall on 15/7/16.
//  Copyright © 2015年 rcshow. All rights reserved.
//

//
//const UInt8 KARAOKE = 0x00;
//const UInt8 STUDIO = 0x01;
//const UInt8 CONCERT = 0x02;
//const UInt8 THEATER = 0x03;
#import <Foundation/Foundation.h>

//typedef NS_ENUM(NSInteger, AuraReverbPresent) {
//    AuraReverbPresent_NONE              = 0xFF,
//    AuraReverbPresent_KARAOKE           = 0x00,
//    AuraReverbPresent_STUDIO            = 0x01,
//    AuraReverbPresent_CONCERT           = 0x02,
//    AuraReverbPresent_THEATER           = 0x03,
//
//};
//
//typedef NS_ENUM(NSInteger, AuraReverbOption) {
//    AuraReverbOption_BEGIN              = 0x00,
//    
//    AuraReverbOption_ROMM_SIZE          = 0x00,
//    AuraReverbOption_PRE_DELAY          = 0x01,
//    AuraReverbOption_REVERBERANCE       = 0x02,
//    AuraReverbOption_DAMPING            = 0x03,
//    AuraReverbOption_TONE_LOW           = 0x04,
//    AuraReverbOption_TONE_HIGH          = 0x05,
//    AuraReverbOption_WET_GAIN           = 0x06,
//    AuraReverbOption_DRY_GAIN           = 0x07,
//    AuraReverbOption_STEREO_WIDTH       = 0x08,
//    
//    AuraReverbOption_MAX                = 0x14 //SIMPLE_TANK_OPTION_MAX = 20
//    
//};

@interface EAudioConfig : NSObject

@property (nonatomic,assign)    UInt32 aacBitRate;

+(instancetype)defaultConfig;

@end



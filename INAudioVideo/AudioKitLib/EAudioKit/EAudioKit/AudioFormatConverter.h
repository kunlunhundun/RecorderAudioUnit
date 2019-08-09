//
//  AudioFormatConverter.h
//  EAudioKit
//
//  Created by cybercall on 15/7/29.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioFormatConverter : NSObject
@property (nonatomic,readonly) char* buffer;
@property (nonatomic,readonly) int   bufferSize;

-(instancetype)init:(AudioStreamBasicDescription)inFormat outputFormat:(AudioStreamBasicDescription)outFormat;
-(BOOL)convert:(char*)inBuffer bufferSize:(int) bufferSize;

@end

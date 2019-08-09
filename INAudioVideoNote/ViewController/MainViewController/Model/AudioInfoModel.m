//
//  AudioInfoModel.m
//  INAudioVideoNote
//
//  Created by kunlun on 30/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "AudioInfoModel.h"

@implementation AudioInfoModel

-(id)init{
    self = [super init];
    if (self) {
        _dateTime = @"";
        _fileName = @"";
        _markTime = @"";
        _durationTime = @"";
    }
    return self;
}


@end

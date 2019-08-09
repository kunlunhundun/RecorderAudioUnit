//
//  AEAudioFileNode.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EAudioGraph.h"

@interface EAudioFileNode : EAudioNode

@property (nonatomic,assign,readonly) UInt64 audioTotalFrames;
@property (nonatomic,readonly)  NSTimeInterval duration;
@property (nonatomic, assign)   NSTimeInterval currentTime;
-(instancetype)initWithAudioFile:(EAudioGraph*)graph AudioFile:(NSString*)audioFile withNodeName:(NSString*)name;


@end

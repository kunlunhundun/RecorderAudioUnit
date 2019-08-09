//
//  EAudioNode.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface EAudioNode : NSObject

@property (nonatomic,assign,readonly) AUNode    audioNode;
@property (nonatomic,strong,readonly) NSString* audioName;
@property (nonatomic,assign,readonly) AudioUnit audioUnit;

-(BOOL)setInputFormat:(int)busNum Format:(AudioStreamBasicDescription)foramt;
-(BOOL)setOutputFormat:(int)busNum Format:(AudioStreamBasicDescription)foramt;
-(BOOL)getInputFormat:(int)busNum Format:(AudioStreamBasicDescription*)format;
-(BOOL)getOutputFormat:(int)busNum Format:(AudioStreamBasicDescription*)format;

@end

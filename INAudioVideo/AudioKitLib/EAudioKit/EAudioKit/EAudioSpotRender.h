//
//  AudioNodeLine.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "auraConfig.h"




//EAudioSpot instance created by EAudioGraph,do not create EAudioSpot instance directly
@interface EAudioSpotRender : NSObject

@property (nonatomic,strong,readonly)    NSString*     name;
@property (nonatomic,assign)             BOOL          loop;
@property (nonatomic,assign)             BOOL          pause;
@property (nonatomic,assign)             float         volume;
@property (nonatomic,assign)             float         gain;
@property (nonatomic,assign)             float         delay;
@property (nonatomic,assign)             float         stereo;//立體音
@property (nonatomic, readonly)          NSTimeInterval duration;    //音频时长，单位：秒
@property (nonatomic, assign)            NSTimeInterval currentTime;   //当前音频位置
@property (nonatomic,readonly)           UInt64        framesCount;


@property (nonatomic,copy)             void(^onPlayBegin)(EAudioSpot*); //开始播放时通知
@property (nonatomic,copy)             void(^onPlayEnd)(EAudioSpot*);   //播放结束时通知
@property (nonatomic,copy)             void(^onReady)(EAudioSpot*);     //音乐文件初始化完成时通知




@end

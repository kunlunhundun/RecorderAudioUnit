//
//  AudioNodeLine.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "auraConfig.h"


typedef NS_ENUM(NSInteger, EAudioEffect) {
    EAudioEffect_Pitch = 0,
    EAudioEffect_Reverb,
    EAudioEffect_EQ
};


/*
 Warning!!!
 //TODO: 這個EAudioSpot已經龐大了，需要分離出來fileSpot,micSpot,streamSpot
 */

//EAudioSpot instance created by EAudioGraph,do not create EAudioSpot instance directly
@interface EAudioSpot : NSObject

@property (nonatomic,strong,readonly)    NSString*     name;

@property (nonatomic,assign)             BOOL          loop;
@property (nonatomic,assign)             BOOL          pause;
@property (nonatomic,assign)             BOOL          isSkip;
@property (nonatomic,assign)             float         volume;
@property (nonatomic,assign)             float         gain;
//@property (nonatomic,assign)             float         delay;
@property (nonatomic,assign)             float         stereo;//立體音
@property (nonatomic, readonly)          NSTimeInterval duration;    //音频时长，单位：秒
@property (nonatomic, assign)            NSTimeInterval currentTime;   //当前音频位置
@property (nonatomic, assign)            NSTimeInterval baseOffset;   //音频基准位置 设置值得话将会调用调整时间基准
@property (nonatomic,readonly)           UInt64        framesCount;
@property (nonatomic,assign)             SInt64        moveFrameCount; //合成混音人声移动的数据个数
//effect property
@property (nonatomic,assign)             float         reverbValue; //混音大小
@property (nonatomic,assign)             int           eqType;
@property (nonatomic,readonly)           NSArray*      eqNames;

@property (nonatomic,assign)             int           pitch;
@property (nonatomic,readonly)           int           frequency;

@property (nonatomic,assign) BOOL hasOriginalMelody;


@property (nonatomic,copy)             void(^onPlayBegin)(EAudioSpot*); //开始播放时通知
@property (nonatomic,copy)             void(^onPlayEnd)(EAudioSpot*);   //播放结束时通知
@property (nonatomic,copy)             void(^onReady)(EAudioSpot*);     //音乐文件初始化完成时通知



-(void)setValueBaseOffset:(NSTimeInterval)valueBaseOffset ; //只是设置音频偏移量 不进行任何操作
-(void)setMoveFrameCountValue;

//添加音效，eg:reverb,pitch,可以多次添加
-(BOOL)addEffect:(EAudioEffect)effect withEffectName:(NSString*)name;

//录音到文件
-(void)startRecord:(NSString*)savePath;

-(void)startRecordRaw:(NSString*)savePath partFlag:(BOOL)partFlag;


-(void)startRecordTest:(NSString*)saveRecordPath;
-(void)stopRecordTest;


//结束录音
-(void)stopRecord;

-(void)setPresentParam:(AuraReverbOption)opt value:(float)v;
-(float)getPresentParam:(AuraReverbOption)opt;
-(void)setPresentParam:(NSArray<NSNumber *>*)opt;

@end

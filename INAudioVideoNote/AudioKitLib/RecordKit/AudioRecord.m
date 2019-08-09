//
//  AudioRecord.m
//  EAudioKit
//
//  Created by zhou on 16/3/23.
//  Copyright © 2016年 rcsing. All rights reserved.
//

#import "AudioRecord.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioRecord () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder * audioRecorder; // 音频录音机
@property (nonatomic, copy) finish finishAction;
@property (nonatomic, copy) audioPowerEvent powerEvent;
@property (nonatomic, strong) NSTimer * timer;

@end


@implementation AudioRecord

+ (AudioRecord *)shareInstance {
    static AudioRecord * _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[AudioRecord alloc] init];
        [_sharedInstance setAudioSession];
    });
    
    return _sharedInstance;
}


/**
 *  设置音频会话
 */
- (void)setAudioSession {
    AVAudioSession * audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
- (NSDictionary *)getAudioSetting {
    NSMutableDictionary * dicM = [NSMutableDictionary dictionary];
    // 设置录音格式
    [dicM setObject:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
    // 设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    // 设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    // 每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    // 是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];

    return dicM;
}


/**
 *  获得录音机对象
 */
- (void)setAudioRecorderWithSaveUrl:(NSURL *)url {
    // 创建录音格式设置
    NSDictionary * setting = [self getAudioSetting];
    // 创建录音机
    NSError * error = nil;
    _audioRecorder = [[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
    _audioRecorder.delegate = self;
    _audioRecorder.meteringEnabled = YES;// 如果要监控声波则必须设置为YES
    if (error) {
        NSLog(@"创建录音机对象时发生错误，错误信息：%@", error.localizedDescription);
    }
}

/**
 *  开始录音
 */
- (void)startRecordWithSavePath:(NSString *)savePath andPowerEvent:(audioPowerEvent)powerEvent; {
    if ([_audioRecorder isRecording] == false) {
        NSLog(@"开始录音");
        _powerEvent = powerEvent;
        
        NSURL * url = [NSURL fileURLWithPath:savePath];
        [self setAudioRecorderWithSaveUrl:url];
        [_audioRecorder record];
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(audioPowerChange) userInfo:nil repeats:true];
    }
}

/**
 *  停止录音
 */
- (void)stopRecordWhenFinish:(finish)finishAction {
    _finishAction = finishAction;
    
    [_timer invalidate];
    _timer = nil;
    
    [self.audioRecorder stop];
}


#pragma mark - 录音声波监控
- (void)audioPowerChange {
    if (_powerEvent) {
        // 更新测量值
        [_audioRecorder updateMeters];
        // 取得第一个通道的音频，-160表示完全安静,0表示最大输入值
        float averagePower = [_audioRecorder averagePowerForChannel: 0];
        
        // 转成分贝
        float level;                      // The linear 0.0 .. 1.0
        float minDecibels = -60.0f;       // Or use -60dB, which I measured in a silent room.
        float decibels    = averagePower;
        
        if (decibels < minDecibels) {
            level = 0.0f;
        }
        else if (decibels >= 0.0f) {
            level = 1.0f;
        }
        else {
            float   root            = 2.0f;
            float   minAmp          = powf(10.0f, 0.05f * minDecibels);
            float   inverseAmpRange = 1.0f / (1.0f - minAmp);
            float   amp             = powf(10.0f, 0.05f * decibels);
            float   adjAmp          = (amp - minAmp) * inverseAmpRange;
            
            level = powf(adjAmp, 1.0f / root);
        }
        
        _powerEvent(level);
    }
}


#pragma mark - 录音机代理方法
/**
 *  录音完成，录音完成后播放录音
 *
 *  @param recorder 录音机对象
 *  @param flag     是否成功
 */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"录音完成!");

    if (_finishAction && flag) {
        _finishAction();
    }
}

@end

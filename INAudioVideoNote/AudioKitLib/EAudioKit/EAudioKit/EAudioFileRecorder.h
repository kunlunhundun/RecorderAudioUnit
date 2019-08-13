//
//  EAudioFileRecorder.h
//  EAudioKit
//
//  Created by kunlun on 30/07/2019.
//  Copyright © 2019 rcsing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EAudioGraph.h"

NS_ASSUME_NONNULL_BEGIN

@interface EAudioFileRecorder : NSObject

@property(nonatomic,copy) void (^eaudioReadFileOutputBlock)(float  *data, UInt32 numFrames);

-(instancetype)init;

/**
 创建文件开始新的录音  mp3 当前文件下继续录音。  wav m4a 开始新的文件录音， 等录音好后 两个音频文件进行合成一个录音文件
 */
-(BOOL)openFile:(NSString*)path AudioStreamFormat:(AudioStreamBasicDescription)audioStreamFormat;
-(OSStatus)pushAudioBuffer:(AudioUnitRenderActionFlags*)ioActionFlags
            AudioTimeStamp:(const AudioTimeStamp *)inTimeStamp
               inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames
           AudioBufferList:(AudioBufferList*)ioData;

/**
 用于mp3录音打开文件后移动到文件尾开始录音
 */
-(void)seekToOriginalFileEnd;
/**
 用于mp3录音打开文件后 丢弃当前的录音， 保存之前的录音
 */
-(void)resetToOriginalFile;
-(void)close;

/**
 两个音频文件合成一个音频文件
 */
+(BOOL)appendTwoFile:(NSString*)firstFilePath secondFilePath:(NSString*)secondFilePath outputFilePath:(NSString*)outputFilePath;

/**
 裁剪音频文件 inputFilePath:要裁剪文件的名称  outputFilePath:输出裁剪文件的名称 startTime:裁剪的开始时间 endTime:裁剪的结束时间  durationTime 总时间
 */
+(BOOL)cutFile:(NSString*)inputFilePath  outputFilePath:(NSString*)outputFilePath startTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime durationTime:(NSTimeInterval)durationTime;

-(BOOL)openExAudioFile:(NSString*)filePath bufferSize:(UInt32)bufferSize;
/**
 读取音频文件，音频数据会以回调的方式返回上去
 */
-(BOOL)getReadFileData;

/**
 文件格式转换 wav-mp3 wav-m4a  m4a-wav
 */
+(BOOL)oneFormatToAudioFile:(NSString*)inputFile targetAudioFile:(NSString*)audioFile;


@end

NS_ASSUME_NONNULL_END

//
//  FileAsynWriter.h
//  EAudioKit
//
//  Created by cybercall on 15/8/26.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface EAudioPcmFile : NSObject

@property (nonatomic,readonly) NSString*  path;
@property (nonatomic,readonly) AudioStreamBasicDescription  audioFormat;
@property (nonatomic,readonly) UInt64 frameCount;
@property (nonatomic,readonly) UInt64 offset;
@property (nonatomic,readonly) UInt64 partFlag;


-(instancetype)initWithPathForWrite:(NSString*)path AudioStreamFormat:(AudioStreamBasicDescription)audioStreamFormat;
-(instancetype)initWithPathForRead:(NSString*)path AudioStreamFormat:(AudioStreamBasicDescription)clientFormat;

-(int)audioFileRead:(AudioBufferList*)ioData inNumberFrames:(UInt32)inNumberFrames;
-(void)audioFileWrite:(AudioBufferList*)ioData inNumberFrames:(UInt32)inNumberFrames;

-(void)seek:(SInt64)frame;
-(void)flush;
-(void)close;
- (void)clear;
- (void)addOPerationQueue:(NSBlockOperation *)operation;

+(void)pcmToAudioFile:(NSString*)pcmFile targetAudioFile:(NSString*)audioFile;

-(instancetype)initWithPathForReadWrite:(NSString*)path AudioStreamFormat:(AudioStreamBasicDescription)clientFormat;

-(void)seekFileEnd;
-(void)seekFileStart;


@end

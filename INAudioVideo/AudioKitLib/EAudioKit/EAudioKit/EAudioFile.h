//
//  AEAudioFileNode.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EAudioGraph.h"
#import "EAudioFeeder.h"

@interface EAudioFile : NSObject<EAudioFeeder>

@property (nonatomic,strong,readonly) NSString*                   audioFile;
@property (nonatomic,assign,readonly) AudioStreamBasicDescription audioFileFormat;
@property (nonatomic,assign,readonly) AudioStreamBasicDescription clientFormat;
@property (nonatomic,assign,readonly) UInt64                      audioFrameCount;
@property (nonatomic,assign,readonly) AudioFileID                 audioFileId;


-(BOOL)openAudioFile:(NSString*)path withAudioDescription:(AudioStreamBasicDescription)clientFormat;

//打开音频文件，并将整个文件读取到内存
-(BOOL)openAudioFileEx:(NSString*)path withAudioDescription:(AudioStreamBasicDescription)clientFormat;

/*EAudioFeeder begin*/
-(int)feedBufferList:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount;
-(BOOL)seekToFrame:(float)second;
-(void)setDelay:(float)second;
-(void)close;
/*EAudioFeeder end*/

@end

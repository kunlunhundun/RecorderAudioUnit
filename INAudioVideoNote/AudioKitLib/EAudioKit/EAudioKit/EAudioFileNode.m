//
//  AEAudioFileNode.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioFileNode.h"
#import "EAudioFile.h"
#import "EAInteranl.h"
#import "EAMicro.h"
#import "EAudioMisc.h"

@interface EAudioFileNode()
@property (nonatomic,strong) EAudioFile* audioFile;
@property (nonatomic,strong) NSString*    audioFilePath;
@end

@implementation EAudioFileNode


-(instancetype)initWithAudioFile:(EAudioGraph*)graph AudioFile:(NSString*)audioFile withNodeName:(NSString*)name
{
    EAudioNode* node = [graph createAudioNode:kAudioUnitType_Generator componentSubType:kAudioUnitSubType_AudioFilePlayer withNodeName:name];
    
    self = [super initWithNode:graph.graph withNode:node.audioNode withName:name];
    _audioFilePath = audioFile;
    
    AudioStreamBasicDescription asbd;
    [node getOutputFormat:0 Format:&asbd];
    
    _audioFile = [[EAudioFile alloc] init];
    [_audioFile openAudioFile:audioFile withAudioDescription:asbd];
    _audioTotalFrames = _audioFile.audioFrameCount;
    if (_audioTotalFrames == 0) {
        _audioFile = nil;
    }
    MARK_INSTANCE();
    return self;
}

-(void)dealloc
{
    UNMARK_INSTANCE();
    CHECK_ERROR(-1,"EAudioFileNode dealloc\n");
    
}

-(void)configAudioFileUnit
{
    UInt64 fileLengthFrames = _audioTotalFrames;
    
    if (fileLengthFrames == 0 ) {
        NSLog(@"err,audio file frame count is 0,maybe err");
        return ;
    }
     AudioFileID audioFileID = _audioFile.audioFileId;
    AudioUnit playerUnit = self.audioUnit;
    OSStatus osStatus = AudioUnitSetProperty(playerUnit, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &audioFileID, sizeof(audioFileID));
    CHECK_ERROR(osStatus,"AudioUnitSetProperty kAudioUnitProperty_ScheduledFileIDs fail");
    
    ScheduledAudioFileRegion region = {0};
    region.mAudioFile = audioFileID;
    region.mCompletionProc = NULL;
    region.mCompletionProcUserData = NULL;
    region.mLoopCount = 0;
    region.mStartFrame = 0;//_startTime * _audioFileFormat.mSampleRate;
    region.mFramesToPlay = fileLengthFrames;//_audioFileFrames - region.mStartFrame;
    region.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    region.mTimeStamp.mSampleTime = 0;
    
    osStatus = AudioUnitSetProperty(playerUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &region, sizeof(ScheduledAudioFileRegion));
    CHECK_ERROR(osStatus,"AudioUnitSetProperty kAudioUnitProperty_ScheduledFileRegion fail");
    
    AudioTimeStamp theTimeStamp = {0};
    if(0){
        theTimeStamp.mFlags = kAudioTimeStampHostTimeValid;
        theTimeStamp.mHostTime = 0;
    }else{
        theTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        theTimeStamp.mSampleTime = -1;
    }
    osStatus = AudioUnitSetProperty(playerUnit,
                                    kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0,
                                    &theTimeStamp, sizeof(theTimeStamp));
    
    AudioStreamBasicDescription asbd;
    [self getOutputFormat:0 Format:&asbd];
    _duration = (double)fileLengthFrames / asbd.mSampleRate;
    
    CHECK_ERROR(osStatus,"AudioUnitSetProperty kAudioUnitProperty_ScheduleStartTimeStamp fail");
    NSLog(@"config fileAudioUnit,total frame:%llu",fileLengthFrames);
}

-(NSTimeInterval)currentTime
{
    return 0;
}


-(void)onNodeConnected:(EAudioNode*)target isConnectToTargetOutput:(BOOL)isConnectToTargetOutput
{
    [super onNodeConnected:target isConnectToTargetOutput:isConnectToTargetOutput];
    if (isConnectToTargetOutput) {
        return;
    }
    
    [self configAudioFileUnit];
}


@end

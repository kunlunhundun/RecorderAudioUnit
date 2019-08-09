//
//  EAMicrophone.m
//  AudioTest
//
//  Created by cybercall on 15/7/14.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAMicrophone.h"
#import <AVFoundation/AVFoundation.h>
#import "EAMicro.h"
#import "EAudioNodeRecorder.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "EAudioMisc.h"



#define CACHE_MIC_RENDER_DATA   0


#define FLAG_NONE                   0
#define FLAG_SHOULD_MAP_CHANNEL     1
#define FLAG_DO_NOTHING             2


@interface EAMicrophone()
{
    AudioComponentInstance      _audioUnit;
    AudioStreamBasicDescription _audioFormat;
    AudioBufferList*            _audioRenderBufferList;
    TPCircularBuffer            _audioTPbuffer;
    BOOL                        _started;
    int                         _flag;

}
@property (nonatomic,strong) EAudioRenderBufferRecorder* bufferRecorder;

-(OSStatus)onMicAudioRecvCallback:(AudioUnitRenderActionFlags*)ioActionFlags
               AudioTimeStamp:(const AudioTimeStamp *)inTimeStamp
                  inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames
              AudioBufferList:(AudioBufferList*)ioData;
@end

//RECORDING
static OSStatus micAudioRecvCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    EAMicrophone* mic = (__bridge EAMicrophone *)(inRefCon);
    OSStatus err = [mic onMicAudioRecvCallback:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];
    return err;
}


@implementation EAMicrophone
#pragma mark -- life cycle --
-(instancetype)init:(AudioStreamBasicDescription) audioFormat
{
    self = [super init];
    _started = NO;
    _flag = FLAG_NONE;
    [self createMicSource:audioFormat];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
    [self stop];
    [self freeBuffer];
    
    if (_audioUnit) {
        AudioComponentInstanceDispose(_audioUnit);
    }
}
#pragma mark -- public interface--


-(void)start
{
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    CHECK_ERROR(status,"AudioOutputUnitStart fail");
    _started = YES;
}

-(void)record:(NSString*)file
{
    if (_bufferRecorder) {
        return;
    }
    EAudioRenderBufferRecorder* recorder = [[EAudioRenderBufferRecorder alloc] init];
    [recorder setup:file AudioStreamFormat:_audioFormat enableSynWrite:NO];
    _bufferRecorder = recorder;
    
}

-(void)stop
{
    _started = NO;
    OSStatus status;
    status = AudioOutputUnitStop(_audioUnit);
    _bufferRecorder = nil;
}

-(AudioStreamBasicDescription)getOutputFormat
{
    return _audioFormat;
}


-(UInt32)renderAudioToBuffer:(const AudioTimeStamp *)inTimeStamp
                inNumberFrames:(UInt32)inNumberFrames
               AudioBufferList:(AudioBufferList*)ioData
{
    OSStatus err ;
#if CACHE_MIC_RENDER_DATA

    while ( 1 ) {
        // Discard any buffers with an incompatible format, in the event of a format change
        AudioBufferList *nextBuffer = TPCircularBufferNextBufferList(&_audioTPbuffer, NULL);
        if ( !nextBuffer ) break;
        if ( nextBuffer->mNumberBuffers == ioData->mNumberBuffers ) break;
        TPCircularBufferConsumeNextBufferList(&_audioTPbuffer);
    }
    
    UInt32 fillCount = TPCircularBufferPeek(&_audioTPbuffer, NULL, &_audioFormat);
    if ( fillCount > inNumberFrames ) {
        UInt32 skip = fillCount - inNumberFrames;
        TPCircularBufferDequeueBufferListFrames(&_audioTPbuffer,
                                                &skip,
                                                NULL,
                                                NULL,
                                                &_audioFormat);
    }
    
    TPCircularBufferDequeueBufferListFrames(&_audioTPbuffer,
                                            &inNumberFrames,
                                            ioData,
                                            NULL,
                                            &_audioFormat);

#else //CACHE_MIC_RENDER_DATA
    AudioUnitRenderActionFlags flag = 0;
    int f1 = ioData->mBuffers[0].mDataByteSize/_audioFormat.mBytesPerFrame;
    
    err = AudioUnitRender(_audioUnit, &flag, inTimeStamp, 1, inNumberFrames, ioData);
    int f2 = ioData->mBuffers[0].mDataByteSize/_audioFormat.mBytesPerFrame;
    
    if (ioData->mBuffers[1].mData == NULL) {
        NSLog(@"ioData->mBuffers[1].mData is NULL");

        return f2;
    }
    else{
      //  NSLog(@"ioData->mBuffers[1].mData have data");
    }
    
    if (_audioFormat.mChannelsPerFrame > 1)
    {
        /*
         *  檢測右聲道數據，雙聲道在某機機上有問題（一個聲道沒聲音）
         *  系統版本9.0(13A4325c),IP6
         */
        if (_flag == FLAG_NONE) {
            void* zero = malloc(ioData->mBuffers[0].mDataByteSize);
            memset(zero, 0, ioData->mBuffers[0].mDataByteSize);
            int c = memcmp(ioData->mBuffers[1].mData, zero, ioData->mBuffers[0].mDataByteSize);
            if ( c == 0 ) {
                _flag = FLAG_SHOULD_MAP_CHANNEL;
                NSLog(@"microphone right channel, no sound,map left channel to right....");
            }else{
                _flag = FLAG_DO_NOTHING;
            }
            free(zero);
        }else if( _flag == FLAG_SHOULD_MAP_CHANNEL )
        {
            int m = MIN(ioData->mBuffers[0].mDataByteSize, ioData->mBuffers[1].mDataByteSize);
            memcpy(ioData->mBuffers[1].mData, ioData->mBuffers[0].mData, m);
        }
    }
    
#endif
   
    
#ifdef DEBUG
    if (inNumberFrames != f2)
    {
        
        if (inNumberFrames < f2){
            //int k1= 1;
        }
        static bool g_test = true;
        if(g_test){
         //   NSLog(@"warning,not enough mic data,require:%d->%d",inNumberFrames,f2);
        }
      
    }
#endif
    return f2;
}



#pragma mark -- private interface --
-(void)createMicSource:(AudioStreamBasicDescription)audioFormat
{
    if (_audioUnit) {
        return;
    }
    
    OSStatus status;
    AudioComponentInstance audioUnit;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
//    desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;

    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    CHECK_ERROR(status,"AudioComponentInstanceNew fail");
    
    _audioUnit = audioUnit;
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    CHECK_ERROR(status,"AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO fail");
    

    AudioStreamBasicDescription micformat;
    UInt32 size = sizeof(micformat);
    status = AudioUnitGetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &micformat, &size);
    if (status != noErr) {
        NSLog(@"AudioUnitGetProperty kAudioUnitProperty_StreamFormat fail");
        return;
    }
    
//    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    CHECK_ERROR(status,"AudioUnitSetProperty kAudioUnitProperty_StreamFormat fail");
    if (status != noErr) {
        return;
    }
    _audioFormat = audioFormat;
    
    [AudioStreamBasicDescriptions printAsbdDif:@"createMicSource" asbdTitle1:@"mic source format" format1:micformat asbdTitle2:@"target mic format" format2:audioFormat];
    
#if  CACHE_MIC_RENDER_DATA
    [self allocBuffer];
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = micAudioRecvCallback;
    callbackStruct.inputProcRefCon = (__bridge void * __nonnull)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                 kAudioUnitScope_Input,// kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    CHECK_ERROR(status,"AudioUnitSetProperty kAudioOutputUnitProperty_SetInputCallback fail");
#endif
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    CHECK_ERROR(status,"AudioUnitInitialize fail");
}

-(void)restart
{
    NSLog(@"EAMicrophone restart");
    [self stop];
    [self allocBuffer];
    [self start];
}

-(void)allocBuffer
{
#if  CACHE_MIC_RENDER_DATA
    [self freeBuffer];
  
    int numberOfBuffers = _audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? _audioFormat.mChannelsPerFrame : 1;
    int channelsPerBuffer = _audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : _audioFormat.mChannelsPerFrame;
    int bytesPerBuffer = _audioFormat.mBytesPerFrame * kMaxFramesPerSlice;
    
    _audioRenderBufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList) + (numberOfBuffers-1) * sizeof(AudioBuffer));
    _audioRenderBufferList->mNumberBuffers = numberOfBuffers;
    
    for (int i=0; i < numberOfBuffers; i++) {
        _audioRenderBufferList->mBuffers[i].mDataByteSize = bytesPerBuffer;
        _audioRenderBufferList->mBuffers[i].mData = malloc(bytesPerBuffer);
        _audioRenderBufferList->mBuffers[i].mNumberChannels = channelsPerBuffer;
    }
    TPCircularBufferInit(&_audioTPbuffer, kAudioBufferLength);
#endif
}

-(void)freeBuffer
{
#if  CACHE_MIC_RENDER_DATA
    if (_audioRenderBufferList) {
        int count = _audioRenderBufferList->mNumberBuffers;
        for (int i=0; i < count; i++) {
            free(_audioRenderBufferList->mBuffers[i].mData);
        }
        free(_audioRenderBufferList);
        _audioRenderBufferList = NULL;
    }
     TPCircularBufferCleanup(&_audioTPbuffer);
#endif
}

-(OSStatus)onMicAudioRecvCallback:(AudioUnitRenderActionFlags*)ioActionFlags
            AudioTimeStamp:(const AudioTimeStamp *)inTimeStamp
               inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames
           AudioBufferList:(AudioBufferList*)ioData
{
    OSStatus err = noErr;
    
    
    AudioUnitRenderActionFlags flag = 0;
    
    
    AudioBuffer buffer;
    buffer.mData = NULL;
    buffer.mDataByteSize = 0;
    buffer.mNumberChannels = 1;
    
    AudioBuffer bufferR;
    bufferR.mData = NULL;
    bufferR.mDataByteSize = 0;
    bufferR.mNumberChannels = 1;
    
    AudioBufferList buffers;
    buffers.mNumberBuffers = 1;
    buffers.mBuffers[0] = buffer;
    
    
    
    err = AudioUnitRender(_audioUnit, &flag, inTimeStamp, inBusNumber, inNumberFrames, &buffers);
    
    
#if  CACHE_MIC_RENDER_DATA
    AudioUnitRenderActionFlags flag = 0;
    AudioTimeStamp timeStamp = *inTimeStamp;
    
    int frame = MIN(kMaxFramesPerSlice, inNumberFrames);
    for (int i=0; i < _audioRenderBufferList->mNumberBuffers; i++) {
        _audioRenderBufferList->mBuffers[i].mDataByteSize = frame * _audioFormat.mBytesPerFrame;
    }
    err = AudioUnitRender(_audioUnit, &flag, &timeStamp, inBusNumber, frame, _audioRenderBufferList);
    CHECK_ERROR(err, "AudioUnitRender fail");
    if (err == noErr) {
        TPCircularBufferCopyAudioBufferList(&_audioTPbuffer, _audioRenderBufferList, &timeStamp, kTPCircularBufferCopyAll, NULL);
        
        err = [_bufferRecorder pushAudioBuffer:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:frame AudioBufferList:_audioRenderBufferList];
    }
#endif
    return err;
}
#pragma mark -- NSNotification --
- (void)interruptionNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue] == AVAudioSessionInterruptionTypeEnded ) {
            NSLog(@"EAMicrophone interruptionNotification: AVAudioSessionInterruptionTypeEnded");

            if (_started) {
                [self restart];
            }
        }
    });
}


@end

//
//  AudioNodeLine.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "EAudioGraph.h"
#import "EAudioSpotRender.h"
#import "EAudioSpot.h"
#import "EAMicro.h"
#import "EAudioMisc.h"
#import "EAInteranl.h"
#import "TPCircularBuffer+AudioBufferList.h"

static OSStatus feedAudioBuffer(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData);



@interface EAudioSpotRender()
{
    EAudioGraph* _graph;
    EAudioNode*  _mixNode;
    BOOL         _isReady;
    BOOL         _shouldNotifyBegin,_shouldNotifyEnd;
    AudioStreamBasicDescription _audioSourceFormat;
    EAudioSpot*  _audioSpot;
    NSMutableArray* _audioBufferLists;
    AudioBufferList* _audioBufferList;
    int              _bufferListFramePos;
    
    UInt64          _totalFrames,_frameOffset;
    
    TPCircularBuffer*            _audioTPbuffer1;
    TPCircularBuffer*            _audioTPbuffer2;

}
@end

@implementation EAudioSpotRender

#pragma mark -- life cycle --
-(instancetype)initWithGraph:(EAudioGraph*)graph withName:(NSString*)spotName Index:(int)busNum
{
    self = [self init];
    _graph = graph;
    _name = spotName;

    _shouldNotifyBegin = YES;
    _shouldNotifyEnd = YES;

    _isReady = NO;


    [self setupAudioSourceNode];
    

    MARK_INSTANCE();
    return self;
}

-(void)dealloc
{
    NSLog(@"EAudioSpotRender:%@ dealloc",_name);
    
    if(_audioTPbuffer1){
        TPCircularBufferCleanup(_audioTPbuffer1);
        free(_audioTPbuffer1);
        _audioTPbuffer1 = NULL;
    }
    if(_audioTPbuffer2){
        TPCircularBufferCleanup(_audioTPbuffer2);
        free(_audioTPbuffer2);
        _audioTPbuffer2 = NULL;
    }
    
    UNMARK_INSTANCE();
}

#define SLIDER_FRAME (1024*4)
#define FRAME_BUFFER_COUNT (1024 * SLIDER_FRAME)

-(void)prepareRender:(NSString*)audioFile
{
    _audioTPbuffer1 = (TPCircularBuffer*)malloc(sizeof(TPCircularBuffer));
    _audioTPbuffer2 = (TPCircularBuffer*)malloc(sizeof(TPCircularBuffer));
    
    int size = _audioSourceFormat.mBytesPerFrame * FRAME_BUFFER_COUNT;
    TPCircularBufferInit(_audioTPbuffer1,  size);
    TPCircularBufferInit(_audioTPbuffer2, size );
    
    NSString* name = [NSString localizedStringWithFormat:@"%@_real",_name ];
    EAudioSpot* spot = [[EAudioSpot alloc] initWithGraph:_graph withName:name Index:0];
    [spot createAudioSource:audioFile withAudioFormat:_audioSourceFormat GraphRenderType:EAGraphRenderType_Offline];
    
    _audioBufferLists = [[NSMutableArray alloc] initWithCapacity:1024];
    _totalFrames = spot.framesCount;
    _frameOffset = 0;
    _audioSpot = spot;
    __weak EAudioSpotRender* weakSelf = self;
    
    _audioSpot.onReady = ^(EAudioSpot* spot)
    {
        [NSThread detachNewThreadSelector:@selector(renderThread:) toTarget:weakSelf withObject:nil];
    };
}

-(void)renderThread:(id)obj
{
    int frames = _audioSourceFormat.mSampleRate * 5.0;
   
    UInt64 frameTotal = _audioSpot.framesCount;
    UInt64 frameRender = 0;
    OSStatus osStatus = noErr;
    while (frameRender < frameTotal)
    {
        int frame = MIN(frames, (frameTotal - frameRender));
        AudioBufferList* bufferList = allocAudioBufferList(_audioSourceFormat, frame);
        osStatus = [_audioSpot feedAudioBuffer:0 AudioTimeStamp:0 inBusNumber:0 inNumberFrames:frames AudioBufferList:bufferList];
        if (osStatus != noErr) {
            freeAudioBufferList(bufferList);
            break;
        }
        frameRender += frame;
        @synchronized(self) {
            NSValue* ptr = [NSValue valueWithPointer:bufferList];
            [_audioBufferLists addObject:ptr];
        }
    }
}



#pragma mark -- private interface --
-(void)onSpotConnectChanged:(BOOL)connected
{

}

//初始化AudioSpot的AudioNode头节点，使用kAudioUnitType_Mixer,音频数据源从这里填充
//所有effect节点都链接到这个节点,MixNode->EffectNode1->EffectNode2...
-(void)setupAudioSourceNode
{
    EAudioNode* audioNode = [_graph createAudioNode:kAudioUnitType_Mixer
                                   componentSubType:kAudioUnitSubType_MultiChannelMixer withNodeName:_name];
    
    AudioUnitParameterValue v = 1.0;
    OSStatus err = AudioUnitSetParameter(audioNode.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, v, 0);
    CHECK_ERROR(err,"AudioUnitSetParameter kMultiChannelMixerParam_Volume failed");
    

    _mixNode = audioNode;

    OSStatus status;
    // Set output callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = feedAudioBuffer;
    callbackStruct.inputProcRefCon = (__bridge void * __nonnull)(self);

    
    status = AUGraphSetNodeInputCallback(_graph.graph, audioNode.audioNode, 0, &callbackStruct);
    CHECK_ERROR(status,"AUGraphSetNodeInputCallback fail");
    
}

//使用音频数据作为音频源_headNode的数据填充
-(void)createAudioSource:(NSString*)audioFilePath withAudioFormat:(AudioStreamBasicDescription)clientFormat GraphRenderType:(EAGraphRenderType)type
{

    AudioStreamBasicDescription audioFormat;
    [_mixNode getInputFormat:0 Format:&audioFormat];
 
    _audioSourceFormat = clientFormat;
    
  
    
}


//_headNode(mixNode)音频数据填充回调，在这里填入需要播放的音频数据
-(OSStatus)feedAudioBuffer:(AudioUnitRenderActionFlags*)ioActionFlags
             AudioTimeStamp:(const AudioTimeStamp*)inTimeStamp
             inBusNumber:(UInt32)inBusNumber
             inNumberFrames:(UInt32)inNumberFrames
            AudioBufferList:(AudioBufferList*)ioData
{

//   // INVOLKE_CALC_DEFINE("feedAudioBuffer")
//    TIME_SLAPS_TRACER("EAudioSpot,feedAudioBuffer",(float)(ioData->mBuffers[0].mDataByteSize)/_audioSourceFormat.mSampleRate/_audioSourceFormat.mBytesPerFrame);
//    LOG_ONCE(@"[%@]feedAudioBuffer info:requireFrameCount:%d | sampleRate:%d -> %0.2fms",_name,(int)(ioData->mBuffers[0].mDataByteSize/_audioSourceFormat.mBytesPerFrame),(int)_audioSourceFormat.mSampleRate,(float)(ioData->mBuffers[0].mDataByteSize)*1000/_audioSourceFormat.mSampleRate/_audioSourceFormat.mBytesPerFrame);
//    
//    if (!_isReady) {
//        [EAudioMisc fillSilence:ioData];
//        return noErr;
//    }
//    
//   
//    if (_shouldNotifyBegin && _onPlayBegin != nil) {
//        _shouldNotifyBegin = NO;
//        NSLog(@"EAudioSpot[%@],notify audio begin...",_name);
//        dispatch_async(dispatch_get_main_queue(), ^(){_onPlayBegin(self);});
//    }
//    
//    UInt32 frameShouldRead = inNumberFrames;
//    char temp[sizeof(AudioBufferList) + sizeof(AudioBuffer)];
//    AudioBufferList* wrap = monitorBufferList(temp, ioData, 0, _audioSourceFormat.mBytesPerFrame);
//    
//    while (true)
//    {
//        while (_audioBufferList == NULL)
//        {
//            NSValue* ptr = nil;
//            @synchronized(self) {
//                
//                if(_audioBufferLists.count > 0 )
//                {
//                    ptr = [_audioBufferLists objectAtIndex:0];
//                    [_audioBufferLists removeObject:0];
//                }
//            }
//            if (ptr == nil) {
//                [NSThread sleepForTimeInterval:0.01];
//            }else{
//                [ptr getValue:&_audioBufferList];
//            }
//        }
//        
//        
//        int frameLen = _audioBufferList->mBuffers[0].mDataByteSize/_audioSourceFormat.mBytesPerFrame - _bufferListFramePos;
//        int frameFeed = MIN(frameShouldRead, frameLen);
//        if (frameFeed > 0) {
//            for(int i=0; i < ioData->mNumberBuffers; i++)
//            {
//                char* p = (char*)_audioBufferList->mBuffers[i].mData + _bufferListFramePos * _audioSourceFormat.mBytesPerFrame;
//                memcpy(wrap->mBuffers[i].mData, p, frameFeed * _audioSourceFormat.mBytesPerFrame);
//            }
//            _frameOffset += frameFeed;
//        }
// 
//        if (frameFeed == frameLen)
//        {
//            freeAudioBufferList(_audioBufferList);
//            _audioBufferList = NULL;
//        }
//        frameShouldRead -= frameFeed;
//        
//        if (frameShouldRead == 0)
//            break;
//        
//        wrap = monitorBufferList(temp, ioData, inNumberFrames - frameShouldRead, _audioSourceFormat.mBytesPerFrame);
//    }
    return noErr;
}


#pragma mark -- effect getter/setter --


-(void)setGain:(float)gain
{

}

-(UInt64)framesCount
{
    return _totalFrames;
}
#pragma mark ----- property -------

- (void)setVolume:(float)volume { // 0 - 1

   // [_graph setVolume:volume AudioSpot:self];
}

-(float)volume
{
    return 0;//[_graph getVolume:self];
}

-(void)setCurrentTime:(NSTimeInterval) v
{

}

-(NSTimeInterval)currentTime
{
    NSTimeInterval d = _frameOffset / _audioSourceFormat.mSampleRate;
    return d;
}

-(NSTimeInterval)duration
{
    NSTimeInterval d = _totalFrames / _audioSourceFormat.mSampleRate;
    return d;
}


@end

#pragma mark -- audio render callback --
static OSStatus feedAudioBuffer(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
    return 0;
//    EAudioSpotRender* spot = (__bridge EAudioSpot *)(inRefCon);
//    return [spot feedAudioBuffer:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];
//    
}


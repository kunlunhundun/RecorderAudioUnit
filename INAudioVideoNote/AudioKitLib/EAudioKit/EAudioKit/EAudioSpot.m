//
//  AudioNodeLine.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioSpot.h"
#import "EAudioGraph.h"
#import "EAInteranl.h"
#import "EAudioFileNode.h"
#import "EAudioNodeRecorder.h"
#import "EAudioMisc.h"
#import "EAMicro.h"
#import "EAMicrophone.h"
#import "EAudioFile.h"
#import "EAPitchDetector.h"
#import "EAAudioPitch.h"
#import "EAAudioPitchSyn.h"
#import "EAudioPcmFile.h"
#import "auraLimiter.h"
#import "EAudioFileRecorder.h"

#ifdef CUSTOMER_REVERB
#import "auraReverb.h"
#endif

static OSStatus feedAudioBuffer(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData);


static OSStatus audioUnitRenderCallback(void* inRefCon,
                                          AudioUnitRenderActionFlags *	ioActionFlags,
                                          const AudioTimeStamp *			inTimeStamp,
                                          UInt32							inBusNumber,
                                          UInt32							inNumberFrames,
                                          AudioBufferList * 	ioData);

@implementation EAudioSpot{
    NSString*     _audioFilePath;
    float         *_outFloatData;
}

#pragma mark -- life cycle --
-(instancetype)initWithGraph:(EAudioGraph*)graph withName:(NSString*)spotName Index:(int)busNum
{
    self = [self init];
    self.graph = graph;
    _curtimeRequire = -1;
    _name = spotName;
    _autoConfigASBD = NO;
    _index = busNum;
    _shouldNotifyBegin = YES;
    _shouldNotifyEnd = YES;
    _loop = NO;
    _isReady = NO;
    _outFloatData = NULL;
    _taskArray = [[NSMutableArray alloc] initWithCapacity:8];
    _baseOffsetTaskArray = [[NSMutableArray alloc] initWithCapacity:3];
    _nodeDictionary = [[NSMutableDictionary alloc] init];
    _hasConnectSpot = NO;
    _moveFrameCount = 0;

    [self setupAudioSourceNode];
    _allowFeedbackMicAudio = [EAudioMisc hasHeadset];
    MARK_INSTANCE();
    return self;
}

-(void)dealloc
{
    NSLog(@"EAudioSpot:%@ dealloc",_name);
    [self cleanup];
    
    UNMARK_INSTANCE();
}

#pragma mark -- public interface --

//添加音效，每个音效都可以起一个对应的effectName名字
//可以通过effectName索引回对应的音效节点，进行设置
-(BOOL)addEffect:(EAudioEffect)effect withEffectName:(NSString*)effectName
{
    if (_headNode == nil) {
        NSLog(@"addEffect failed,no audio source,create it first..");
        return NO;
    }
    EAudioNode* node = _nodeDictionary[effectName];
    if (node != nil) {
        NSLog(@"effect node(%@) has exists..",effectName);
        return NO;
    }
    if (effect == EAudioEffect_Pitch) {
        
        node = [_graph createAudioNode:kAudioUnitType_FormatConverter
                      componentSubType:kAudioUnitSubType_NewTimePitch
                          withNodeName:effectName];
        
        //        if ( _fileNode == _tailNode) {
        //            AudioStreamBasicDescription asbd;
        //            [node getInputFormat:0 Format:&asbd];
        //            [_fileNode setOutputFormat:0 Format:asbd];
        //        }
        
        
    }else if( effect == EAudioEffect_Reverb )
    {
        node = [_graph createAudioNode:kAudioUnitType_Effect
                      componentSubType:kAudioUnitSubType_Reverb2
                          withNodeName:effectName];
        if(_reverbNode == nil){
            _reverbNode = node;
        }
    }else if( effect == EAudioEffect_EQ ){
        node = [_graph createAudioNode:kAudioUnitType_Effect
                      componentSubType:kAudioUnitSubType_AUiPodEQ
                          withNodeName:effectName];
        _eqNode = node;
        
    }
    else{
        NSLog(@"addEffect not support!");
        return NO;
    }
    if (node == nil) {
        return NO;
    }
    BOOL ret = [_graph connectAudioNode:_tailNode FromBusNum:0 ToNode:node ToBusNum:0];
    if (ret) {
        _nodeDictionary[effectName] = node;
        _tailNode = node;
        return YES;
    }
    return NO;
}

-(void)startRecord:(NSString*)savePath
{
    if (_recorder == nil) {
        NSLog(@"EAudioSpot start recording...");
        _recorder = [[EAudioNodeRecorder alloc] init];
        [_recorder attachAudioNode:_tailNode.audioUnit outputPath:savePath enableSynWrite:NO];
    }
}

-(void)stopRecord
{
    if (_recorder != nil) {
        NSLog(@"EAudioSpot stop recording...");
        [_recorder detach];
        _recorder = nil;
    }
    if (_rawRecorder != nil) {
        [self stopRawRecord];
    }
}


-(void)startRecordMutableFormatPath:(NSString*)saveRecordPath{
    
    _bufferRecorder = [[EAudioRenderBufferRecorder alloc] init];
    AudioStreamBasicDescription defaultStreamFormat = _audioSourceFormat;//[AudioStreamBasicDescriptions nonInterleavedFloatStereoAudioDescription];
    BOOL bSetup = [_bufferRecorder setup:saveRecordPath AudioStreamFormat:defaultStreamFormat enableSynWrite:NO];
    if (bSetup) {
        NSLog(@"recording begin...bSetup:%d\n",bSetup);
        
    }
}

-(void)stopRecordMutableFormatPath{
    
    [_bufferRecorder close];
    _bufferRecorder = nil;
}

-(void)startRecordContinueFilePath:(NSString*)recordPath{
    
    _continueRecord = [[EAudioFileRecorder alloc]init];
    [_continueRecord openFile:recordPath AudioStreamFormat:_audioSourceFormat];
    [_continueRecord seekToOriginalFileEnd];
}

-(void)stopRecordContinue{
    [_continueRecord close];
    _continueRecord = nil;
}
-(void)resetRecordContinue{
    [_continueRecord resetToOriginalFile];
    _continueRecord = nil;
}


-(void)startRecordRaw:(NSString*)savePath partFlag:(BOOL)partFlag
{
    if (_rawRecorder == nil) {
        //_rawRecorder = [[EAudioRenderBufferRecorder alloc ] init:YES];
       // [_rawRecorder setup:savePath AudioStreamFormat:_audioSourceFormat enableSynWrite:NO];
        _rawRecorder = [[EAudioPcmFile alloc] initWithPathForWrite:savePath AudioStreamFormat:_audioSourceFormat];
        
        NSLog(@"EAudioSpot[%@] start rawRecording...",_name);
    }
}

-(void)stopRawRecord
{
    if (_rawRecorder != nil) {
        NSLog(@"EAudioSpot stop rawRecording...");
        _rawRecorder = nil;
    }
}

#pragma mark -- notification from audioGraph --
-(void)onSpotConnectChanged:(BOOL)connected
{
    _hasConnectSpot = YES;
    if (_microphone) {
        if (connected) {
            //节点已经链接起来，可以开始采集mic数据了
            [_microphone start];
        }else{
            [_microphone stop];
        }
    }
    if(connected)
    {
        OSStatus err = AudioUnitAddRenderNotify(_tailNode.audioUnit, audioUnitRenderCallback, (__bridge void * __nullable)(self));
    }
}

-(void)onAudioGraphDestroyed
{
    [self cleanup];
}

#pragma mark -- private interface --
//初始化AudioSpot的AudioNode头节点，使用kAudioUnitType_Mixer,音频数据源从这里填充
//所有effect节点都链接到这个节点,MixNode->EffectNode1->EffectNode2...
-(void)setupAudioSourceNode
{
    EAudioNode* audioNode = [_graph createAudioNode:kAudioUnitType_Mixer
                                   componentSubType:kAudioUnitSubType_MultiChannelMixer withNodeName:_name];
    
    AudioUnitParameterValue v = 1.0;
    OSStatus err = AudioUnitSetParameter(audioNode.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, v, 0);
    CHECK_ERROR(err,"AudioUnitSetParameter kMultiChannelMixerParam_Volume failed");
    

    _headNode = audioNode;
    _tailNode = audioNode;
    OSStatus status;
    // Set output callback
    _callbackInfo = (callback_info*)malloc(sizeof(callback_info));
    _callbackInfo->inRefCon = (__bridge void * __nonnull)(self);
    _callbackInfo->isValid = true;
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = feedAudioBuffer;
    callbackStruct.inputProcRefCon = _callbackInfo;
    //    OSStatus status = AudioUnitSetProperty(audioNode.audioUnit,
    //                                  kAudioUnitProperty_SetRenderCallback,
    //                                  kAudioUnitScope_Global,
    //                                  0,
    //                                  &callbackStruct,
    //                                  sizeof(callbackStruct));
    //    CHECK_ERROR(status,"AudioUnitSetProperty kAudioUnitProperty_SetRenderCallback fail");
    
    status = AUGraphSetNodeInputCallback(_graph.graph, audioNode.audioNode, 0, &callbackStruct);
    CHECK_ERROR(status,"AUGraphSetNodeInputCallback fail");
    
}

-(void)cleanup
{
    if (_callbackInfo) {
        if(0){
            //FIX_ME,THIS will cause memory leak!!!
            _callbackInfo->isValid = false;
        }else{
            free(_callbackInfo);
            _callbackInfo = NULL;
        }
    }
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopRecord];
    
    if (_outFloatData) {
        
        free(_outFloatData);
        _outFloatData = NULL;
    }
    if (_pitchProcess) {
        [_pitchProcess close];
        _pitchProcess = nil;
    }
    if (_pitchProcessSyn) {
        [_pitchProcessSyn close];
        _pitchProcessSyn = nil;
    }

    if(_taskArray){
        if (_taskArray.count > 0) {
            NSLog(@"EAudioSpot[%@],taskArray count:%d",_name,_taskArray.count);
        }
        _taskArray = nil;
    }
    if (_baseOffsetTaskArray) {
        [_baseOffsetTaskArray removeAllObjects];
        _baseOffsetTaskArray = nil;
    }
    _auraReverb = nil;
    _microphone = nil;
    _audioFile = nil;
    _micNode = nil;


}
//使用音频数据作为音频源_headNode的数据填充
-(void)createAudioSource:(NSString*)audioFilePath withAudioFormat:(AudioStreamBasicDescription)clientFormat GraphRenderType:(EAGraphRenderType)type
{
    if (!_headNode) {
        return;
    }

    AudioStreamBasicDescription audioFormat;
    [_headNode getInputFormat:0 Format:&audioFormat];
 
    _audioSourceFormat = clientFormat;
    _audioFilePath = audioFilePath;
    EAudioFile* audioFile = [[EAudioFile alloc] init];
#if 1
    [audioFile openAudioFile:audioFilePath withAudioDescription:clientFormat];
#else
    [audioFile openAudioFileEx:audioFilePath withAudioDescription:clientFormat];
#endif
    _audioFile = audioFile;
    
    __weak EAudioSpot* weakSelf = self;
#if 1
    if (type == EAGraphRenderType_Offline) {
        _pitchProcessSyn = [[EAAudioPitchSyn alloc ] initWithAudioFile:clientFormat audioFile:audioFile];
        _pitchProcessSyn.onReady = ^{
            [weakSelf notifyReady];
        };
        _audioFileFeeder = _pitchProcessSyn;
    }else{
        
        _pitchProcess = [[EAAudioPitch alloc ]initWithAudioFile:1.0 audioFormat:clientFormat audioFile:audioFile];
        _pitchProcess.onReady = ^{
            [weakSelf notifyReady];
        };
        _audioFileFeeder = _pitchProcess;
    }
#else
    _audioFileFeeder = _audioFile;
#endif

    _totalFrames = _audioFile.audioFrameCount;
    _frameOffset = 0;
    
    [self setupDefaultEffect];
    
}

//使用mic作为音频源_headNode的数据填充
-(void)createMicAudioSource:(AudioStreamBasicDescription)clientFormat GraphRenderType:(EAGraphRenderType)type
{
    if (!_headNode) {
        return;
    }
    _microphone = [[EAMicrophone alloc] init: clientFormat];

    AudioStreamBasicDescription asbd = [_microphone getOutputFormat];
    _audioSourceFormat = asbd;
    [_headNode setInputFormat:0 Format:asbd];
    //[_headNode setOutputFormat:0 Format:asbd];
    
    _pitchDetector = [[EAPitchDetector alloc] initWithAudioFormat:_audioSourceFormat];
    _isReady = YES;
    if (self.onReady != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onReady(self);
        });
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [self setupDefaultEffect];
}

-(void)setupDefaultEffect
{
#if ENABLE_DEFAULT_GAIN
    [self addEffect:EAudioEffect_Reverb withEffectName:@"default_reverb_for_gain"];
#endif
}


-(void) notifyReady
{
    _isReady = YES;
    if (self.onReady != nil) {
        self.onReady(self);
    }
}

//_headNode(mixNode)音频数据填充回调，在这里填入需要播放的音频数据
-(OSStatus)feedAudioBuffer:(AudioUnitRenderActionFlags*)ioActionFlags
             AudioTimeStamp:(const AudioTimeStamp*)inTimeStamp
             inBusNumber:(UInt32)inBusNumber
             inNumberFrames:(UInt32)inNumberFrames
            AudioBufferList:(AudioBufferList*)ioData
{

   // INVOLKE_CALC_DEFINE("feedAudioBuffer")
    TIME_SLAPS_TRACER("EAudioSpot,feedAudioBuffer",(float)(ioData->mBuffers[0].mDataByteSize)/_audioSourceFormat.mSampleRate/_audioSourceFormat.mBytesPerFrame);
    LOG_ONCE(@"[%@]feedAudioBuffer info:requireFrameCount:%d | sampleRate:%d -> %0.2fms",_name,(int)(ioData->mBuffers[0].mDataByteSize/_audioSourceFormat.mBytesPerFrame),(int)_audioSourceFormat.mSampleRate,(float)(ioData->mBuffers[0].mDataByteSize)*1000/_audioSourceFormat.mSampleRate/_audioSourceFormat.mBytesPerFrame);
    
    if (!_isReady) {
        [EAudioMisc fillSilence:ioData];
        return noErr;
    }
    
    assert(inNumberFrames == ioData->mBuffers[0].mDataByteSize/_audioSourceFormat.mBytesPerFrame);
    
    [self execuseBlockTask];
    if (_microphone) {//将mic的数据填入，回话mic的声音
        TIME_SLAPS_TRACER("microphone feedAudioBuffer",0.005);
        int frameRender = [_microphone renderAudioToBuffer:inTimeStamp inNumberFrames:inNumberFrames AudioBufferList:ioData];
        
        /*
            _microphone->AudioUnitRender會修改ioData->mBuffers->mDataByteSize大小，
            超出inNumberFrames也有，這是不算BUG?!
         */
        int old = inNumberFrames;
        inNumberFrames = frameRender;
        if (_rawRecorder != nil) {
            [_rawRecorder audioFileWrite:ioData inNumberFrames:inNumberFrames];
        }
        
        _totalFrames += inNumberFrames;//just for mic
        
        if (_onMicDataBlock) {
            if (_outFloatData == NULL ) {
                _outFloatData =  (float*)calloc(4096, sizeof(char));
                memset(_outFloatData, 0, sizeof(char)*4096);
            }
            memcpy(_outFloatData, ioData->mBuffers[0].mData, ioData->mBuffers[0].mDataByteSize);
            _onMicDataBlock(_outFloatData,ioData->mBuffers[0].mDataByteSize,1);
        }
        if (_bufferRecorder) {
            [_bufferRecorder pushAudioBuffer:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];
        }
        if (_continueRecord) {
            [_continueRecord pushAudioBuffer:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];
        }
        
        if (!_allowFeedbackMicAudio)
        {
            [EAudioMisc fillSilence:ioData];
        }
        
        
    }else if(_audioFileFeeder){//播放音频文件
        
        TIME_SLAPS_TRACER("audioFile feedAudioBuffer",0.005);
        
        if (_graph.graphRenderType == EAGraphRenderType_Offline && _baseOffset > 0 && _moveFrameCount > 0) {
           // NSLog(@"_moveFrameCount:%lld,inNumberFrames:%ld\n",_moveFrameCount,inNumberFrames);
            if(inNumberFrames > 0){
                [EAudioMisc fillSilence:ioData];
                if (_moveFrameCount > inNumberFrames/2) {
                    _moveFrameCount =  _moveFrameCount - inNumberFrames;
                    return noErr;
                }
            }
            _moveFrameCount =  0;
            _frameOffset = 0 ;
        }
        
        int count = [_audioFileFeeder feedBufferList:ioData frameCount:inNumberFrames];
        if ([_name containsString:@"micRecorder"]){
         //   NSLog(@"EAudioSpot[%@] baseoffset:%.3f..",_name,_baseOffset);
        }
        if (_graph.graphRenderType == EAGraphRenderType_Offline && _baseOffset > 0){
        }
        if (count <= 0) {
             [EAudioMisc fillSilence:ioData];
        }
        if(count == 0)
        {
            if (_loop) {
                _frameOffset = 0;
                [_audioFileFeeder seekToFrame:0];
            }else{
                if ( _shouldNotifyEnd && _onPlayEnd) {
                    _shouldNotifyEnd = NO;
                    typeof(self) __weak weakSelf = self;
                    NSLog(@"EAudioSpot[%@],notify audio end...",_name);
                    dispatch_async(dispatch_get_main_queue(), ^(){_onPlayEnd(weakSelf);});
                }
            }
        }else
        {
            if (_rawRecorder != nil) {
                [_rawRecorder audioFileWrite:ioData inNumberFrames:inNumberFrames];
            }
            
            if (_bufferRecorder) {
                
                OSStatus err = [_bufferRecorder pushAudioBuffer:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];
                
                if (err) {
                    NSLog(@"recording begin...bSetup:%d\n",err);
                }
            }
            if ((ioData->mNumberBuffers>1)) {
                if (_hasOriginalMelody) {
                    memcpy(ioData->mBuffers[0].mData, ioData->mBuffers[1].mData, ioData->mBuffers[1].mDataByteSize);   // mBuffers[1]是原唱， 0是伴奏
                }
                else{
                    memcpy(ioData->mBuffers[1].mData, ioData->mBuffers[0].mData, ioData->mBuffers[0].mDataByteSize); //testliurg
                }
            }
            if (_onPlayDataBlock) {
                if (_outFloatData == NULL ) {
                    _outFloatData =  (float*)calloc(4096, sizeof(char));
                    memset(_outFloatData, 0, sizeof(char)*4096);

                }
                memcpy(_outFloatData, ioData->mBuffers[0].mData, ioData->mBuffers[0].mDataByteSize);
                _onPlayDataBlock(_outFloatData,ioData->mBuffers[0].mDataByteSize,1);
            }
            _frameOffset += count;
        }
    };
    if (_shouldNotifyBegin && _onPlayBegin != nil) {
        _shouldNotifyBegin = NO;
        NSLog(@"EAudioSpot[%@],notify audio begin...",_name);
        typeof(self) __weak weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(){_onPlayBegin(weakSelf);});
    }

    //memcpy(ioData,bufferWrap,sizeof(bufferWrap));
    
    return noErr;
}


-(OSStatus)audioUnitRenderCallback:(AudioUnitRenderActionFlags*)ioActionFlags
            AudioTimeStamp:(const AudioTimeStamp*)inTimeStamp
               inBusNumber:(UInt32)inBusNumber
            inNumberFrames:(UInt32)inNumberFrames
           AudioBufferList:(AudioBufferList*)ioData
{
    
    TIME_SLAPS_TRACER("audioUnitRenderCallback",0.005);

    /*inNumberFrames與mDataByteSize不匹配的，有大有小，以mDataByteSize為準 */
    //assert(inNumberFrames <= frames);
    UInt32 frames = ioData->mBuffers[0].mDataByteSize / _audioSourceFormat.mBytesPerFrame;
    
    [self doAudioFilter:inTimeStamp inNumberFrames:frames AudioBufferList:ioData];
    
    return noErr;
}


-(void)doAudioFilter:(const AudioTimeStamp*)inTimeStamp inNumberFrames:(UInt32)inNumberFrames AudioBufferList:(AudioBufferList*)ioData
{
    if (_pitchDetector) {
        TIME_SLAPS_TRACER("pitchDetector,processPitch",0.005);
        [_pitchDetector processPitch:inTimeStamp inNumberFrames:inNumberFrames AudioBufferList:ioData];
    }
#ifdef CUSTOMER_REVERB
    if (_auraReverb != nil)
    {
        TIME_SLAPS_TRACER("auraReverb,process audio",0.005);
        [_auraReverb process:ioData];        
    }
#endif
    
    [self doStereoEffect:ioData];
    
    [self doCustomVolumGain:ioData];
    
}

-(void)doCustomVolumGain:(AudioBufferList*)ioData
{
    if (_curCustomGain <= 0 ) {
        return;
    }
    if(!(_audioSourceFormat.mFormatFlags & kLinearPCMFormatFlagIsFloat))
        return;
   
    float g = _curCustomGain + 1;
    for(int i=0; i < ioData->mNumberBuffers; i++)
    {
        AudioBuffer* audioBuffer = &(ioData->mBuffers[i]);
        float* data = (float*)audioBuffer->mData;
        for (int j=0; j<audioBuffer->mDataByteSize; j+=sizeof(float)) {
            float v = *data;
            *data = v * g;
//#ifdef DEBUG
//            float f = *data;
//            if ( f >= 1.0 ){
//                NSLog(@"doCustomVolumGain,%0.2f > 1",f);
//            }
//#endif
            data++;
        }
    }
    
    if (_limiter == nil)
    {
        _limiter = [[auraLimiter alloc] initWithAudioFormat:_audioSourceFormat];
    }
    [_limiter process:ioData];

}

-(void)doStereoEffect:(AudioBufferList*)ioData
{
    if (_channelDelayFrameOffsetRequire == 0){
        _delayDelayOffsetFrame = 0;
        return;
    }
    
    if (_channelDelayFrameOffsetRequire != _delayDelayOffsetFrame)
    {
        NSLog(@"stereco:%0.3fs->%0.3fs",_delayDelayOffsetFrame/_audioSourceFormat.mSampleRate,_channelDelayFrameOffsetRequire/_audioSourceFormat.mSampleRate);
        int require = _channelDelayFrameOffsetRequire;
        _delayDelayOffsetFrame = require;
        
        int delaySize = _delayDelayOffsetFrame * _audioSourceFormat.mBytesPerFrame;
        
        int size = MAX(delaySize, ioData->mBuffers[0].mDataByteSize);
        _channelDelayBuffer = [[EACircleBuffer alloc] initWithBufferSize:size];
        void* zero = malloc(delaySize);
        memset(zero, 0, delaySize);
        [_channelDelayBuffer pushData:zero dataByteSize:delaySize];
        free(zero);
    }
    
    char* left = (char*)(ioData->mBuffers[0].mData);
    int leftLen = ioData->mBuffers[0].mDataByteSize;

    int dataSave = [_channelDelayBuffer pushData:left dataByteSize:leftLen];
    if (dataSave < leftLen) {
        char* tail = (left + dataSave);
        int tailLen = (leftLen - dataSave);
        [ _channelDelayBuffer cacheData:tail dataByteSize:tailLen];
        [_channelDelayBuffer popData:left dataByteSize:leftLen];
        
        void* cache = [_channelDelayBuffer getCacheData];
        int s = [_channelDelayBuffer pushData:cache dataByteSize:tailLen ];
        assert(s == leftLen - dataSave);
    }else{
        [_channelDelayBuffer popData:left dataByteSize:leftLen];
    }
}

-(void)execuseBlockTask
{
    
    if (_baseOffsetTaskArray.count>0) {
        
        NSMutableArray* baseTaskArray = [[NSMutableArray alloc] initWithCapacity:1];
        
        @synchronized (_baseOffsetTaskArray) {
            
            [baseTaskArray addObjectsFromArray:_baseOffsetTaskArray];
            [_baseOffsetTaskArray removeAllObjects];
        }
        BaseOffsetBlockTask block =  [baseTaskArray objectAtIndex:0];
        block();
        [baseTaskArray removeAllObjects];
    }
    
    if (_taskArray.count <= 0) {
        return;
    }
    NSMutableArray* taskArray = [[NSMutableArray alloc] initWithCapacity:16];
    @synchronized(_taskArray)
    {
        [taskArray addObjectsFromArray:_taskArray];
        [_taskArray removeAllObjects];
    }
    
    int count = (int)taskArray.count;
    NSLog(@"run block task in audioThread,count:%d....name:%@\n",count,_name);
    
    for(int i=0; i < count; i++){
        BlockTask block =  [taskArray objectAtIndex:i];
        block();
        
    }
    [taskArray removeAllObjects];
}

#pragma mark -- effect getter/setter --
-(void)setReverbValue:(float)value
{
    if (_reverbNode != nil) {
        AudioUnitParameterValue vv = value * 100;
        AudioUnitParameterValue v = MAX(0,MIN(vv, 100));
        NSLog(@"%@:setReverbValue:%0.2f",_name,v);
        OSStatus err = AudioUnitSetParameter(_reverbNode.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, v, 0);
        CHECK_ERROR(err, "AudioUnitSetParameter kReverb2Param_DryWetMix fail");
    }
}
-(float)reverbValue
{
    AudioUnitParameterValue v = 0;
    if (_reverbNode != nil) {
        OSStatus err = AudioUnitGetParameter(_reverbNode.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, &v);
        CHECK_ERROR(err, "AudioUnitGetParameter kReverb2Param_DryWetMix fail");
    }
    return v;
}

-(void)setGain:(float)gain
{

    if (_reverbNode != nil) {
        AudioUnitParameterValue vv = gain * 40;
        vv -= 20;
        AudioUnitParameterValue v = MAX(-20,MIN(vv, 20));
        NSLog(@"%@:setGain:%0.2f",_name,v);
        OSStatus err = AudioUnitSetParameter(_reverbNode.audioUnit, kReverb2Param_Gain, kAudioUnitScope_Global, 0, v, 0);
        CHECK_ERROR(err, "AudioUnitSetParameter kReverb2Param_DryWetMix fail");
    }
}

-(void)setEqType:(int)value
{
    if ( _eqNode == nil) {
        return;
    }
    
    CFArrayRef EQPresetsArray;
    UInt32 size = sizeof(EQPresetsArray);
    OSStatus result = AudioUnitGetProperty(_eqNode.audioUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &EQPresetsArray, &size);
    CHECK_ERROR_MSG_RET(result, "AudioUnitSetProperty kAudioUnitProperty_PresentPreset fail");

//     int count = CFArrayGetCount(EQPresetsArray);
//     for (int i = 0; i < count; ++i) {
//         AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(EQPresetsArray, i);
//         NSLog(@"-->%i:%@",i,aPreset->presetName);
//     }
    
    AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(EQPresetsArray, value);
    result = AudioUnitSetProperty(_eqNode.audioUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, aPreset, sizeof(AUPreset));
    CHECK_ERROR(result, "AudioUnitSetProperty kAudioUnitProperty_PresentPreset fail");
    if (result == noErr) {
        _eqType = value;
    }
#ifdef DEBUG
    NSLog(@"choose:%@",aPreset->presetName);
#endif
}

-(NSArray*)eqNames
{
    NSMutableArray* arrays = [[NSMutableArray alloc ] initWithCapacity:16];
    if ( _eqNode == nil) {
        return arrays;
    }
    
    CFArrayRef EQPresetsArray;
    UInt32 size = sizeof(EQPresetsArray);
    OSStatus result = AudioUnitGetProperty(_eqNode.audioUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &EQPresetsArray, &size);
    
    int count = CFArrayGetCount(EQPresetsArray);
    for (int i = 0; i < count; ++i) {
        AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(EQPresetsArray, i);
        NSString* p = (__bridge NSString*)aPreset->presetName;
        [arrays addObject:p];
    }
    return arrays;
}

-(int)frequency
{
    if (_pitchDetector != nil) {
        return _pitchDetector.frequency;
    }
    return 0;
}

-(void)setPitch:(int)pitch
{
    _pitch = pitch;
    if(_pitchProcess != nil )
    {
        [_pitchProcess setPitch:_pitch];
    }else if(_pitchProcessSyn != nil){
        [_pitchProcessSyn setPitch:_pitch];
    }
}

-(void)setPresentParam:(AuraReverbOption)opt value:(float)v
{
#ifdef CUSTOMER_REVERB
    if (_auraReverb == nil)
        return;
    
    [_auraReverb setReverbOption:opt Value:v];

#endif
}
-(float)getPresentParam:(AuraReverbOption)opt
{
#ifdef CUSTOMER_REVERB
    if (_auraReverb == nil)
        return 0;
    
    return [_auraReverb getReverbOption:opt];
    
#endif
}
-(void)setPresentParam:(NSArray<NSNumber *>*)opt
{
    
#ifdef CUSTOMER_REVERB
    float v[AuraReverbOption_MAX];
    memset(v, 0, sizeof(v));
    
    int len = opt.count;
    if (len > AuraReverbOption_MAX) {
        len = AuraReverbOption_MAX;
    }
    for (int i=0; i<len; i++) {
        v[i] = [opt[i] floatValue];
    }
    
    if (_auraReverb == nil) {
        auraReverb* reverb = [[auraReverb alloc]initWithAudioFormat:_audioSourceFormat];
        _auraReverb = reverb;
    }
    
    return [_auraReverb setReverbOpts:v];
    
#endif
}
-(UInt64)framesCount
{
    return _totalFrames;
}
#pragma mark ----- property -------



#define VOLUME_FACTOR   0.5 //音量100%的位置
//0 ~ VOLUME_FACTOR  :setVolume
//VOLUME_FACTOR+ ~ 1 :setGain
- (void)setVolume:(float)volume//// 0 - 1
{
    if(volume < 0)
        volume = 0;
    if (volume > 1) {
        volume = 1;
    }

    if (volume >=VOLUME_FACTOR) {
        [self.graph setVolume:1 AudioSpot:self];
        if (VOLUME_FACTOR == 1) {
            _curCustomGain = 0;
        }else{
            _curCustomGain = (volume - VOLUME_FACTOR)/(1-VOLUME_FACTOR);
        }
    }else
    {
        _curCustomGain = 0;
        float v = volume/VOLUME_FACTOR;
        [self.graph setVolume:v AudioSpot:self];
    }
    
}

-(float)volume
{
    return [self.graph getVolume:self];
}


-(void)setCurrentTimeInternal:(NSTimeInterval) v
{
  //  NSTimeInterval absV = _baseOffset + v;
    if (v == 0 && _graph.baseOffset > 0) {
        v = 0.60;  //调整时设置的参数 非EAGraphRenderType_Offline时
    }
    NSTimeInterval absV = v - _baseOffset ;

    if (_microphone)
    {
        SInt64 frameOffset = absV * _audioSourceFormat.mSampleRate;
        _totalFrames = frameOffset;
        if (_rawRecorder) {
            [_rawRecorder seek:frameOffset];
            
            NSLog(@"_rawRecorder: V:%.2f  baseoffset:%.3f,_totalFrames:%d \n ",v,_baseOffset,frameOffset);
            
        }
//        [self clearFile:absV];
    }else
    {
        UInt64 frameOffset = absV * _audioSourceFormat.mSampleRate;
        NSLog(@"ppppspot:%@setCurrentTimeInternal:%0.3f---->absV:%0.3f---->_frameOffset:%ld\n",_name,v,absV,_frameOffset);
        _frameOffset = frameOffset;
        if (_frameOffset > _totalFrames) {
            _frameOffset = _totalFrames;
        }
        _shouldNotifyEnd = YES;
//        if (_baseOffset == 0 && _graph.baseOffset < 0 && [self.name containsString:@"audioFile"]) { //当最终合成时需要移动伴奏
//            absV = 0 - _graph.baseOffset;
//        }
        [_audioFileFeeder seekToFrame:absV];
        
        if (_graph.graphRenderType == EAGraphRenderType_Offline) {
            
            [_audioFileFeeder seekToFrame:0+_graph.captureOffset];

            NSLog(@"EAGraphRenderType_Offline:%@---->%0.3f captureOffset :%.0.3f\n",_name,_graph.baseOffset,_graph.captureOffset);

            if (_baseOffset == 0 && _graph.baseOffset > 0) {  //伴奏在前，人声在后，调整伴奏
                [_audioFileFeeder seekToFrame:_graph.baseOffset+_graph.captureOffset];
            }
            if (_baseOffset < 0) {  //伴奏在后，人声在前，调整人声
                [_audioFileFeeder seekToFrame:absV+_graph.captureOffset];
            }
        }
        
        if(_frameOffset == 0){
            _shouldNotifyBegin = YES;
        }
        [self clearFile:absV];
    }
    
}
- (void)openNewAudioFile{
    if (!_audioFileNew) {
        _audioFileNew = [[EAudioFile alloc] init];
    }
    [_audioFileNew openAudioFile:_audioFilePath withAudioDescription:_audioSourceFormat];
}
- (void)clearFile:(NSTimeInterval)skipTimes{
    if (self.isSkip && _rawRecorder) {
        [self openNewAudioFile];
        typeof(self) __weak weakSelf = self;
        [_rawRecorder clear];
        self.isSkip = NO;
        NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
            [weakSelf tempBufferList:skipTimes];
        }];
        [_rawRecorder addOPerationQueue:operation];
    }
}
- (void)tempBufferList:(float)skipTimes{
    UInt32 bufferFrameCount = skipTimes * _audioSourceFormat.mSampleRate;
    AudioBufferList * bufferTempList = allocAudioBufferList(_audioSourceFormat,bufferFrameCount);
    [_audioFileNew feedBufferList:bufferTempList frameCount:bufferFrameCount];
    [_rawRecorder audioFileWrite:bufferTempList inNumberFrames:bufferFrameCount];
}


-(void)updateCurrentTimeInteranl
{
    if (_curtimeRequire >= 0) {

        @synchronized(self) {
            NSTimeInterval require = _curtimeRequire;
            _curtimeRequire = -1;
          
            [self setCurrentTimeInternal:require];
        }
    }
}

-(void)setCurrentTime:(NSTimeInterval) v
{
    //統一放到播放線程執行，否則ExtAudioFileRead這些api會掛
    @synchronized(self) {
        _curtimeRequire = v;
    }
    
    BlockTask block = ^{
        [self updateCurrentTimeInteranl];
        
    };
    
    @synchronized(_taskArray) {
        [_taskArray addObject:block];
    }
}

-(NSTimeInterval)currentTime
{
    if (_microphone)
    {
        return _totalFrames/_audioSourceFormat.mSampleRate;
    }else
    {
        if (_curtimeRequire >=0)
        {
            return _curtimeRequire;
        }
        NSTimeInterval d = _frameOffset / _audioSourceFormat.mSampleRate;
        d -= _baseOffset;
        return d;
    }
}


-(void)setValueBaseOffset:(NSTimeInterval)valueBaseOffset
{
    _baseOffset = valueBaseOffset ;
    _graph.baseOffset = valueBaseOffset;
}

-(void)setMoveFrameCountValue{
    if (_baseOffset < 0) {
        _moveFrameCount = 0;
        return ;
    }
    UInt64 frameOffset = _baseOffset * _audioSourceFormat.mSampleRate;
    _moveFrameCount = frameOffset;
    
}

-(void)setBaseOffset:(NSTimeInterval) baseOffset
{
    NSTimeInterval offset = baseOffset - _baseOffset;
    if(offset > -0.0049 && offset < 0.0049){
        return;
    }
    
    _baseOffset = baseOffset ;
    _graph.baseOffset = _baseOffset;
    
    if (_hasConnectSpot) {
        BaseOffsetBlockTask block = ^{
            
            NSTimeInterval cur = _frameOffset / _audioSourceFormat.mSampleRate;
            
            NSLog(@"blocksetBaseOffset baseOffset:%.3f....cur:%.3f\n",_baseOffset,cur);
            _baseOffset = baseOffset;
            
            [_graph setCurrentTimeInternal:cur];
            
        };
        @synchronized(_baseOffsetTaskArray) {
            if (_baseOffsetTaskArray.count>0) {
                [_baseOffsetTaskArray removeAllObjects];
            }
            [_baseOffsetTaskArray addObject:block];
        }
    }else{
        NSTimeInterval cur = _frameOffset / _audioSourceFormat.mSampleRate;
        
        NSLog(@"setBaseOffset baseOffset:%.3f.... cur-->:%.3f\n",_baseOffset,cur);
        _baseOffset = baseOffset;
        [_graph setCurrentTimeInternal:cur];
    }
    
    // [self setCurrentTimeInternal:0];
    
}


-(NSTimeInterval)duration
{
    NSTimeInterval d = _totalFrames / _audioSourceFormat.mSampleRate;
    return d;
}
-(void)setPause:(BOOL)pause
{
    if (_pause == pause) {
        return;
    }
    _pause = pause;
    NSLog(@"EAudioSpot[%@] pause=%d",_name,_pause);
    
    AudioUnitParameterValue isOnValue  = _pause;
    OSStatus err = AudioUnitSetParameter(_headNode.audioUnit, kMultiChannelMixerParam_Enable, kMultiChannelMixerParam_Enable, 0, isOnValue, sizeof(isOnValue));
    CHECK_ERROR(err, "AudioUnitSetParameter kMultiChannelMixerParam_Enable fail");
}



-(void)setStereo:(float)stereo
{
    const float MAX_STEREC = 2.0;
    if ( stereo > MAX_STEREC) {
        stereo = MAX_STEREC;
    }
    if (stereo < 0) {
        stereo = 0;
    }

    int delay = _audioSourceFormat.mSampleRate * stereo;
    _channelDelayFrameOffsetRequire = delay;
}

//
//- (void)setPitch:(NSDictionary*)data {
//    if (!data[@"pitch"]) { return; }
//    AudioUnit unit = [_graph getUnitNamed:@"pitch"];
//    float pitch = [data[@"pitch"] floatValue] * 2400; // [-1,1] -> [-2400,2400]
//    AudioUnitSetParameter(unit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0);
//}

#pragma mark --Notifications---
- (void)audioRouteChangeNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _allowFeedbackMicAudio = [EAudioMisc hasHeadset];
    });
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

    callback_info* cb = (callback_info*)inRefCon;
    if (!cb->isValid) {
        return noErr;
    }else{
        EAudioSpot* spot = (__bridge EAudioSpot *)(cb->inRefCon);
        return [spot feedAudioBuffer:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];
    }
}

static OSStatus audioUnitRenderCallback(void* inRefCon,
                                        AudioUnitRenderActionFlags *	ioActionFlags,
                                        const AudioTimeStamp *			inTimeStamp,
                                        UInt32							inBusNumber,
                                        UInt32							inNumberFrames,
                                        AudioBufferList * 	ioData)
{
    
    BOOL isPostRender = (*ioActionFlags & kAudioUnitRenderAction_PostRender);
    if (!isPostRender) { return noErr; }
    
    EAudioSpot* spot = (__bridge EAudioSpot *)(inRefCon);

    OSStatus status = [spot audioUnitRenderCallback:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];


    return status;
}



//
//  EAudioGraph.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioGraph.h"
#import "EAudioFileNode.h"
#import "EAInteranl.h"
#import "EAMicro.h"
#import "EAudioNodeRecorder.h"
#import "EAudioMisc.h"



#define MAX_AUDIO_LINE 8




static OSStatus audioUnitRenderCallback(void* inRefCon,
                                        AudioUnitRenderActionFlags *	ioActionFlags,
                                        const AudioTimeStamp *			inTimeStamp,
                                        UInt32							inBusNumber,
                                        UInt32							inNumberFrames,
                                        AudioBufferList * 	ioData);
static void interAppConnectedChangeCallback(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement)
{
    NSLog(@"interAppConnectedChangeCallback");
}

@implementation EAudioGraph
#pragma mark -- life cycle --
-(instancetype)initWithName:(NSString*)name SampleRate:(float)sampleRate withType:(EAGraphRenderType)type
{
    
    self = [super init];
    _name = name;
    _audioSpots = [[NSMutableArray alloc] initWithCapacity:MAX_AUDIO_LINE];
    for (int i=0; i < MAX_AUDIO_LINE; i++) {
        [_audioSpots addObject:[NSNull null]];
    }
    _interrupted = NO;
    _started = NO;
    _offlineRendering = NO;
    _interruptOfflineRender = NO;
    _offsetRequire = -1;
    _baseOffset = 0;
    _captureOffset = 0;
    _graphRenderType = type;
    
    OSStatus err = NewAUGraph(&_graph);
    if (err == noErr) {
        err = AUGraphOpen(_graph);
        err = AUGraphInitialize(_graph);
        CHECK_ERROR(err,"AUGraphInitialize failed");
    }
    
    // [self setupDefaultAudioFormat:sampleRate];
    [self setupDefaultAudioFormat:0];
    
    [self configGraph];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    [audioSession setActive:YES error:NULL];
    [self resetOutputTarget];
    
    // Register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaServiceResetNotification:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    MARK_INSTANCE();
    NSLog(@"\n\n----------------EAudioGraph:%@ created--------------",_name);
    return self;
}

-(instancetype)initWithName:(NSString*)name withType:(EAGraphRenderType)type
{
    return [self initWithName:name SampleRate:44100 withType:type];
}

-(void)dealloc
{
    UNMARK_INSTANCE();
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
    if (_offlineRendering) {
        //wait for stop;
        _interruptOfflineRender = YES;
        while (_offlineRendering) {
            [NSThread sleepForTimeInterval:0.5];
            NSLog(@"running offline rendering,waitting for stop...");
        }
        NSLog(@"running offline rendering,stoped...");
    }
    
    [self stopGraph];
    if (_audioSpots != nil) {
        int count = [_audioSpots count];
        for (int i=0; i < count; i++) {
           __weak EAudioSpot* spot = [_audioSpots objectAtIndex:i];
            if (spot != [NSNull null]) {
                [spot stopRecord];
                [spot onAudioGraphDestroyed];
            }
        }
        _audioSpots = nil;
    }
    
    _recorder = nil;
    
    if (_graph) {
        AUGraphClose(_graph);
        DisposeAUGraph(_graph);
    }
    
    NSLog(@"EAudioGraph:%@ disposed",_name);
}

#pragma mark -- graph/public interface --

-(void)startGraph
{
    if (_outputNode == nil) {
        NSLog(@"err,plz call setup first");
        return;
    }
    NSLog(@"EAudioGraph startGraph");
    Boolean running = false;
    AUGraphIsRunning(_graph, &running);
    if (!running) {
        Boolean updated = false;
        AUGraphUpdate(_graph, &updated);
        OSStatus err = AUGraphStart(_graph);
        CHECK_ERROR(err,"AUGraphStart failed");
        if (err == noErr) {
            _started = YES;
        }
    }
}

-(void)stopGraph
{
    [self stopRecord];
    
    NSLog(@"EAudioGraph stopGraph");
    OSStatus err = AUGraphStop(_graph);
    if (err != noErr) {
        CHECK_ERROR(err,"AUGraphStop failed");
    }
    _offsetRequire = -1;
    _started = NO;
}



-(BOOL)startRecord:(NSString*)savePath
{
    if (_outputNode != nil ) {
        NSLog(@"EAudioGraph start recording...");
        return [self startRecord:_outputNode.audioUnit SaveTo:savePath];
    }
    return NO;
}

-(BOOL)startRecord:(AudioUnit)audioUnit SaveTo:(NSString*)savePath
{
    return [self startRecord:audioUnit SaveTo:savePath enableSynWrite:NO];
}

-(BOOL)startRecord:(AudioUnit)audioUnit SaveTo:(NSString*)savePath enableSynWrite:(BOOL)synWrite
{
    if (_recorder == nil) {
        _recorder = [[EAudioNodeRecorder alloc] init];
        return [_recorder attachAudioNode:audioUnit outputPath:savePath enableSynWrite:synWrite];
    }
    return NO;
}

-(void)stopRecord
{
    if (_recorder != nil) {
        NSLog(@"EAudioGraph stop recording...");
        [_recorder detach];
        _recorder = nil;
    }
}

-(void)startOfflineRender:(NSString*)savePath
          TotalFrameCount:(UInt64)frameCount
             ProcessBlock:(mixProcessBlock)block
{
    if (_outputNode == nil) {
        NSLog(@"err,plz call setup first");
        if (block) {
            block(-1);
        }
        return;
    }
    _offlineRendering = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(){
        [self startOfflineRender:_outputNode.audioUnit RenderTo:savePath TotalFrameCount:frameCount ProcessBlock:block];
        _offlineRendering = NO;
    });
}

-(void)startOfflineRender:(UInt64)frameCount
              renderBlock:(renderCallbackBlock)block
{
    if (_outputNode == nil) {
        NSLog(@"err,plz call setup first");

        return;
    }
    _offlineRendering = YES;
    
    [self startOfflineRenderLoop:_outputNode.audioUnit TotalFrameCount:frameCount ProcessBlock:nil RenderBlock:block];
    
    _offlineRendering = NO;
 
}

#pragma mark -- AudioSpot/public interface --

-(EAudioSpot*)createAudioSpot:(NSString*)audioFile withName:(NSString*)spotName;
{
    int idx = [self getEmptySpotIndex];
    if (idx < 0) {
        return nil;
    }
    
    EAudioSpot* spot = [[EAudioSpot alloc] initWithGraph:self withName:spotName Index:idx];
    [_audioSpots setObject:spot atIndexedSubscript:idx];
    [spot createAudioSource:audioFile withAudioFormat:_defaultStreamFormat GraphRenderType:_graphRenderType];
    return spot;
    
}

-(EAudioSpot*)createMicAudioSpot:(NSString*)spotName
{
    int idx = [self getEmptySpotIndex];
    if (idx < 0) {
        return nil;
    }
    
    EAudioSpot* spot = [[EAudioSpot alloc] initWithGraph:self withName:spotName Index:idx];
    [_audioSpots setObject:spot atIndexedSubscript:idx];

    [spot createMicAudioSource:_micAudioFormat GraphRenderType:_graphRenderType];

    return spot;
}

-(void)addAudioSpot:(EAudioSpot*)spot
{
    EAudioNode* pot = spot.tailNode;
    int busNum = spot.index;
    [self connectAudioNode:pot FromBusNum:0 ToNode:_mixNode ToBusNum:busNum];
    [spot onSpotConnectChanged:YES];
}

-(void)removeAudioSpot:(EAudioSpot*)spot
{
    [self disconnectAudioNode:_mixNode destInputBusNum:spot.index];
    [_audioSpots setObject:[NSNull null] atIndexedSubscript:spot.index];
    [spot onSpotConnectChanged:NO];
}


#pragma mark -- AudioNode/public interface --
-(EAudioNode*)createAudioNode:(OSType)nodeComponentType
             componentSubType:(OSType)nodeComponentSubType
                 withNodeName:(NSString*)nodeName
{
    
    AUNode node;
    AudioComponentDescription acd;
    acd.componentType = nodeComponentType;
    acd.componentSubType = nodeComponentSubType;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;
    OSStatus err = AUGraphAddNode(_graph, &acd, &node);
    if(err == noErr){
        NSLog(@"audioNode created:%@",nodeName);
        
        EAudioNode* item = [[EAudioNode alloc] initWithNode:_graph withNode:node withName:nodeName];
        
        UInt32 maximumFramesPerSlice = 4096;
        OSStatus result = AudioUnitSetProperty (
                                       item.audioUnit,
                                       kAudioUnitProperty_MaximumFramesPerSlice,
                                       kAudioUnitScope_Global,
                                       0,
                                       &maximumFramesPerSlice,
                                       sizeof (maximumFramesPerSlice)
                                       );
        
        CHECK_ERROR(result,"AudioUnitSetProperty (set mixer unit input stream format)");
        
        AudioStreamBasicDescription audioFormat = _defaultStreamFormat;
        [item setInputFormat:0 Format:audioFormat];
        
        if(!(nodeComponentType == kAudioUnitType_Output &&
           nodeComponentSubType == kAudioUnitSubType_RemoteIO)){
            [item setOutputFormat:0 Format:audioFormat];
        }
        return item;
    }else{
        CHECK_ERROR(err,"createAudioNode failed,AUGraphAddNode!");
    }
    
    return nil;
}

-(void)removeAudioNode:(EAudioNode*)node
{
    AUGraphRemoveNode(_graph,node.audioNode);
}

-(BOOL)connectAudioNode:(EAudioNode*)fromNode FromBusNum:(int)fromBusNum ToNode:(EAudioNode*)toNode ToBusNum:(int)toBusNum
{
    if (fromNode == nil ||
        toNode == nil) {
        NSLog(@"connectAudioNode faile,param can't be null");
        return NO;
    }
    OSStatus err = AUGraphConnectNodeInput(_graph,
                                           fromNode.audioNode, fromBusNum,
                                           toNode.audioNode, toBusNum);
    CHECK_ERROR(err,"connectAudioNode failed");
    if (err == kAudioUnitErr_FormatNotSupported)
    {
        AudioStreamBasicDescription a1,a2;
        [fromNode getOutputFormat:fromBusNum Format:&a1];
        [toNode getInputFormat:toBusNum Format:&a2];
        return NO;
    }else if (err != noErr )
        return NO;
    
    NSLog(@"connect: %@[%d] -> %@[%d]",fromNode.audioName,fromBusNum,toNode.audioName,toBusNum);
    
    [fromNode onNodeConnected:toNode isConnectToTargetOutput:NO];
    [toNode onNodeConnected:fromNode isConnectToTargetOutput:YES];
    return  YES;
}


-(BOOL)disconnectAudioNode:(EAudioNode*)destNode destInputBusNum:(int)busNum
{
    OSStatus err = AUGraphDisconnectNodeInput(_graph, destNode.audioNode, busNum);
    CHECK_ERROR(err,"AUGraphDisconnectNodeInput failed");
    if (err != noErr) {
        return NO;
    }
    return  YES;
}

#pragma mark -- property getter/setter
- (void)setPause:(BOOL)pause
{
    if (_outputNode == nil) {
        return;
    }
    if (pause) {
        if (![self isRunning])
            return;
        
        [self stopInternal];
        _offsetRequire = -1;
    }else{
        if ([self isRunning])
            return;
        
        [self startGraph];
    }
}

-(BOOL)pause
{
    if (_outputNode == nil) {
        return YES;
    }
    
    [self stopInternal];
    
    Boolean running = false;
    AUGraphIsRunning(_graph, &running);
    return !running;
}

- (void)setVolume:(float)volume { // 0 - 1
    
    if (_mixNode == nil) {
        return;
    }
    AudioUnitParameterValue v = LIMIT_VALUE(volume,0,1);
    AudioUnit unit = _mixNode.audioUnit;
    OSStatus err = AudioUnitSetParameter(unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, v, 0);
    CHECK_ERROR(err,"AudioUnitSetParameter kMultiChannelMixerParam_Volume failed");
}

- (float)volume
{
    if (_mixNode == nil) {
        return 0;
    }

    AudioUnitParameterValue v = 0;
    AudioUnit unit = _mixNode.audioUnit;
    OSStatus err = AudioUnitGetParameter(unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, &v);
    CHECK_ERROR(err,"AudioUnitGetParameter kMultiChannelMixerParam_Volume failed");
    return v;
}

- (float)reverbValue
{
    AudioUnitParameterValue v = 0;
    if (_reverbNode != nil) {
        OSStatus err = AudioUnitGetParameter(_reverbNode.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, &v);
        CHECK_ERROR(err, "AudioUnitGetParameter kReverb2Param_DryWetMix fail");
    }
    return v;
}

-(void)setReverbValue:(float)value
{
    if (_reverbNode != nil) {
        float vv = value * 100;
        float v = MAX(0,MIN(vv, 100));
        NSLog(@"%@:setReverbValue:%0.2f",_name,v);
        OSStatus err = AudioUnitSetParameter(_reverbNode.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, v, 0);
        CHECK_ERROR(err, "AudioUnitSetParameter kReverb2Param_DryWetMix fail");
    }
}


-(void)setEqType:(int)value
{
    if (_eqNode != nil) {
        
         if (_eqType == value )
             return;
        
        CFArrayRef EQPresetsArray;
        UInt32 size = sizeof(EQPresetsArray);
        OSStatus result = AudioUnitGetProperty(_eqNode.audioUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &EQPresetsArray, &size);
        CHECK_ERROR_MSG_RET(result, "AudioUnitSetProperty kAudioUnitProperty_PresentPreset fail");
        
//        int count = CFArrayGetCount(EQPresetsArray);
//        for (int i = 0; i < count; ++i) {
//            AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(EQPresetsArray, i);
//            NSLog(@"-->%i:%@",i,aPreset->presetName);
//        }
        
        AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(EQPresetsArray, value);
        result = AudioUnitSetProperty(_eqNode.audioUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, aPreset, sizeof(AUPreset));
        CHECK_ERROR(result, "AudioUnitSetProperty kAudioUnitProperty_PresentPreset fail");
        if (result == noErr) {
            _eqType = value;
        }
        NSLog(@"choose:%@",aPreset->presetName);
    }
}

-(float)getVolume:(EAudioSpot*)spot
{
    AudioUnitParameterValue v = 0;
    
    AudioUnit unit = _mixNode.audioUnit;
    OSStatus err = AudioUnitGetParameter(unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, spot.index, &v);
    CHECK_ERROR(err,"AudioUnitGetParameter kMultiChannelMixerParam_Volume failed");
    return v;
}

- (void)setVolume:(float)volume AudioSpot:(EAudioSpot*)spot { // 0 - 1
    
    if (_mixNode == nil) {
        return;
    }
    AudioUnitParameterValue v = LIMIT_VALUE(volume,0,1);
    //v = v * 5;
    NSLog(@"%@:setVolume:%0.2f",_name,v);
    AudioUnit unit = _mixNode.audioUnit;
    OSStatus err = AudioUnitSetParameter(unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, spot.index, v, 0);
    CHECK_ERROR(err,"AudioUnitSetParameter kMultiChannelMixerParam_Volume failed");
}


-(NSTimeInterval)currentTime
{
    if (_offsetRequire >= 0) {
        return _offsetRequire;
    }
    
    NSTimeInterval time = 0;
    int count = _audioSpots.count;
    for (int i=0; i < count; i++) {
        EAudioSpot* spot = [_audioSpots objectAtIndexedSubscript:i];
        if (spot != [NSNull null]) {
            if (time < spot.currentTime)
                time = spot.currentTime;
        }
    }
    return time;
}

-(void)setCurrentTime:(NSTimeInterval)time
{
    BOOL bRunning = [self isRunning];
    if (bRunning) {
        _offsetRequire = time;
        NSLog(@"EAudioGraph,setCurrentTime,playing,delay setCurrentTime");
    }else{
        [self setCurrentTimeInternal:time];
    }
}
- (void)setIsSkip:(BOOL)isSkip{
    _isSkip = isSkip;
    NSUInteger count = _audioSpots.count;
    for (int i=0; i < count; i++) {
        EAudioSpot* spot = [_audioSpots objectAtIndexedSubscript:i];
        if (spot != [NSNull null]) {
            NSLog(@"CurrentTimeInternalcountII:%d, name:%@ time:%.3f\n",i,spot.name,time);
            spot.isSkip = isSkip;
        }
    }
}

-(void)setCurrentTimeInternal:(NSTimeInterval)time
{
    NSLog(@"EAudioGraphttt,setCurrentTimeInternal:%.3f,_audioSpots.count:%d\n",time,(int)(_audioSpots.count));
    int count = _audioSpots.count;
    for (int i=0; i < count; i++) {
        EAudioSpot* spot = [_audioSpots objectAtIndexedSubscript:i];
        if (spot != [NSNull null]) {
            NSLog(@"CurrentTimeInternalcountII:%d, name:%@ time:%.3f\n",i,spot.name,time);
            [spot setCurrentTime:time];
            
            //  [spot setCurrentTimeInternal:time];
        }
    }
}



-(void)setRenderCB:(renderCallbackBlock)renderCB
{
    if (_renderCB == nil && renderCB) {
        OSStatus status = AudioUnitAddRenderNotify(_outputNode.audioUnit, audioUnitRenderCallback, (__bridge void * __nullable)(self));
    
    }else if (_renderCB && renderCB == nil)
    {
        AudioUnitRemoveRenderNotify(_outputNode.audioUnit, audioUnitRenderCallback, (__bridge void * __nullable)(self));
    }
    
    _renderCB = renderCB;
    

}

#pragma mark -- private interface --

static OSStatus audioDataRenderNotify(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData)
{
    EAudioGraph* SELF = (__bridge EAudioGraph*)inRefCon;
    NSTimeInterval require = SELF->_offsetRequire;
    
    if (require >= 0) {
        SELF->_offsetRequire = -1;
        NSLog(@"audioDataRenderNotify EAudioGraph,setCurrentTimeInternal:%0.2f",require);
        [SELF setCurrentTimeInternal:require];
    }
    return noErr;
}

-(void)configGraph
{
    OSStatus err;
    [self createMixNode];
    if (_graphRenderType == EAGraphRenderType_RealTime)
    {
        NSString* name = [NSString stringWithFormat:@"%@_ioNode",_name];
        _ioNode = [self createAudioNode:kAudioUnitType_Output
                       componentSubType:kAudioUnitSubType_RemoteIO
                           withNodeName:name];
        _outputNode = _ioNode;
        
        // Enable IO for recording
        UInt32 flag = 1;
        OSStatus status = AudioUnitSetProperty(_ioNode.audioUnit,
                                               kAudioOutputUnitProperty_EnableIO,
                                               kAudioUnitScope_Input,
                                               kInputBus,
                                               &flag,
                                               sizeof(flag));
        CHECK_ERROR(status,"AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO fail");
        
        
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = audioDataRenderNotify;
        callbackStruct.inputProcRefCon = (__bridge void * __nonnull)self;
        status = AudioUnitSetProperty(_ioNode.audioUnit,
                                      kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Global,
                                      kInputBus,
                                      &callbackStruct,
                                      sizeof(callbackStruct));
        
        
    }else if(_graphRenderType == EAGraphRenderType_Offline)
    {
        NSString* name = [NSString stringWithFormat:@"%@_genericNode",_name];
        _genericNode = [self createAudioNode:kAudioUnitType_Output
                            componentSubType:kAudioUnitSubType_GenericOutput
                                withNodeName:name];
        _outputNode = _genericNode;
    }
    
    EAudioNode* lastNode = (_lastEffectNode != nil) ? _lastEffectNode : _mixNode;
    [self connectAudioNode:lastNode FromBusNum:0 ToNode:_outputNode ToBusNum:0];
    
    err = AudioUnitAddPropertyListener(_outputNode.audioUnit, kAudioUnitProperty_IsInterAppConnected, interAppConnectedChangeCallback, (__bridge void*)self);
    CHECK_ERROR(err, "AudioUnitAddPropertyListener(kAudioUnitProperty_IsInterAppConnected)");
    
}

-(void)setupDefaultAudioFormat:(float)sampleRate
{

    //_defaultStreamFormat = [AudioStreamBasicDescriptions nonInterleaved16BitStereoAudioDescription];
    _defaultStreamFormat = [AudioStreamBasicDescriptions nonInterleavedFloatStereoAudioDescription];
  
    _micAudioFormat = _defaultStreamFormat;
    
    if (sampleRate > 0) {
        _defaultStreamFormat.mSampleRate = sampleRate;
    }
    
    NSLog(@"setup default audio input/output format");
    [AudioStreamBasicDescriptions printASBD:_defaultStreamFormat];

}

//所有EAudioSpot都链接 到这个mixNode
-(void)createMixNode
{
    
    NSString* mixName = [NSString stringWithFormat:@"%@_mixNode",_name];
    _mixNode = [self createAudioNode:kAudioUnitType_Mixer
                    componentSubType:kAudioUnitSubType_MultiChannelMixer
                        withNodeName:mixName];
    //_lastEffectNode = _mixNode;
    UInt32 busCount = MAX_AUDIO_LINE;
    OSStatus err = AudioUnitSetProperty(_mixNode.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount));
    CHECK_ERROR(err,"AudioUnitSetProperty kAudioUnitProperty_ElementCount failed!");
    
    /*
    _reverbNode = [self createAudioNode:kAudioUnitType_Effect
                    componentSubType:kAudioUnitSubType_Reverb2
                                      withNodeName:@"graphReverbNode"];
    
    [self connectAudioNode:_mixNode FromBusNum:0 ToNode:_reverbNode ToBusNum:0];
    _lastEffectNode = _reverbNode;
    
    _eqNode = [self createAudioNode:kAudioUnitType_Effect
                       componentSubType:kAudioUnitSubType_AUiPodEQ
                           withNodeName:@"graphEqNode"];
    
    [self connectAudioNode:_reverbNode FromBusNum:0 ToNode:_eqNode ToBusNum:0];
    _lastEffectNode = _eqNode;
     */
   
}

-(int)getEmptySpotIndex
{
    int count = _audioSpots.count;
    for (int i=0; i < count; i++) {
        EAudioSpot* spot = [_audioSpots objectAtIndexedSubscript:i];
        if (spot == [NSNull null]) {
            return i;
        }
    }
    return -1;
}
-(BOOL)isRunning
{
    if (_ioNode)
    {
        Boolean running;
        UInt32 size = sizeof(running);
        OSStatus err = (AudioUnitGetProperty(_outputNode.audioUnit, kAudioOutputUnitProperty_IsRunning, kAudioUnitScope_Global, 0, &running, &size));
        
        if (err == noErr) {
            return running;
        }
        return NO;
    }
     return YES;
    
}

- (void)stopInternal
{

    NSLog(@"EAudioGraph stopInternal");
    AUGraphStop(_graph);
    _offsetRequire = -1;
    if ( [self isRunning] ) {
        // Ensure top IO unit is stopped (AUGraphStop may fail to stop it)
        AudioOutputUnitStop(_outputNode.audioUnit);
    }
    
    if ( !_interrupted ) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];
    }
}

-(void)restartInteranl
{
    if ( _started && ![self isRunning] )
    {
        NSLog(@"restartInteranl");
        [self startGraph];
    }
}

-(void)startOfflineRenderLoop:(AudioUnit) audioUnit
              TotalFrameCount:(UInt64)frameCount
                 ProcessBlock:(mixProcessBlock)processblock
                 RenderBlock:(renderCallbackBlock)renderBlock
{
    
    AudioStreamBasicDescription nodeAudioFormat;
    UInt32 fSize = sizeof (nodeAudioFormat);
    memset(&nodeAudioFormat, 0, fSize);
    OSStatus err = AudioUnitGetProperty(audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Output,
                                        0,
                                        &nodeAudioFormat,
                                        &fSize);
    CHECK_ERROR_MSG_RET(err, "AudioUnitGetProperty,kAudioUnitProperty_StreamFormat fail");
    NSLog(@"----->startOfflineRenderLoop mix------->\n");
    
    AudioUnitRenderActionFlags flags = kAudioOfflineUnitRenderAction_Render;
    SInt64 numFrames = frameCount;
    SInt64 framesPerBuffer = 1024 * 4;
    
    int channelCount = nodeAudioFormat.mChannelsPerFrame;
    AudioBufferList* bufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer)*(channelCount-1));
    bufferList->mNumberBuffers = channelCount;
    SInt64 bufferSize = framesPerBuffer * nodeAudioFormat.mBytesPerFrame;
    for (int i=0; i<nodeAudioFormat.mChannelsPerFrame; i++)
    {
        bufferList->mBuffers[i].mNumberChannels = 1;
        bufferList->mBuffers[i].mDataByteSize = bufferSize;
        bufferList->mBuffers[i].mData = malloc(bufferSize);
    }
    
    int frameRender = 0;
    int prcocess = -1;
    for (UInt32 i=0; frameRender<numFrames; i++)
    {
        SInt64 frame = framesPerBuffer;
        if (numFrames - frameRender < framesPerBuffer) {
            frame = numFrames - frameRender;
        }
        TIME_SLAPS_TRACER("EAudioGraph,offline render frame",0.1);
        AudioTimeStamp audioTimeStamp = {0};
        memset (&audioTimeStamp, 0, sizeof(audioTimeStamp));
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        audioTimeStamp.mSampleTime = frameRender;
        err = AudioUnitRender(audioUnit, &flags, &audioTimeStamp, 0, frame, bufferList);
        CHECK_ERROR(err, "AudioUnitRender failed");
        if (err != noErr) {
            prcocess = -1;
            break;
        }
        if ( _interruptOfflineRender) {
            prcocess = -1;
            processblock = nil;
            renderBlock = nil;
            break;
        }
        
        //pcm數據囘調
        if (renderBlock != nil){
            if(!renderBlock(frame,bufferList))
            {
                renderBlock = nil;
                processblock = nil;
                break;
            }
        }
        
        //進度通知
        frameRender += frame;
        int p = (frameRender/numFrames);
        if (processblock && p != prcocess) {
            prcocess = p;
            if(!processblock(prcocess)){
                processblock = nil;
                break;
            }
        }
        
        //重置數據（可能會被改了）
        for (int j=0; j<nodeAudioFormat.mChannelsPerFrame; j++)
        {
            bufferList->mBuffers[j].mNumberChannels = 1;
            bufferList->mBuffers[j].mDataByteSize = bufferSize;
        }
    }
    
    //free buffer list
    for (int j=0; j<channelCount; j++)
    {
        free(bufferList->mBuffers[j].mData);
    }
    free(bufferList);
    bufferList = NULL;
    if (processblock) {
        if (prcocess != -1 && prcocess != 100) {
            processblock(100);
        }else{
            processblock(prcocess);
        }
        
    }
    NSLog(@"startOfflineRenderLoop end...");
}


-(void)startOfflineRender:(AudioUnit) audioUnit
                 RenderTo:(NSString*)savePath
          TotalFrameCount:(UInt64)frameCount
             ProcessBlock:(mixProcessBlock)block
{
    
    NSLog(@"startOfflineRender start...");
    _graphRenderType = EAGraphRenderType_Offline;

    NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
    if ([self startRecord:audioUnit SaveTo:savePath enableSynWrite:YES]) {
        __block int mixProcess = 0;
        mixProcessBlock process = ^(int process){
            mixProcess = process;
            if (process >= 100) {
                process = 99;
            }
            return block(process);
        };
        [self startOfflineRenderLoop:audioUnit TotalFrameCount:frameCount ProcessBlock:process RenderBlock:nil];
        
        [self stopRecord];
        NSTimeInterval t2 = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval t = t2 - t1;
        NSLog(@"startOfflineRender end,totalFrames:%lld,slapse:%.2fs,speed:%0.2fn/s...",frameCount,t,frameCount/t);
        if (mixProcess >= 100) {
            block(100);
        }
    }else{
        NSLog(@"!!!!err,startOfflineRender start recorder error!");
        if (block != nil) {
            dispatch_sync(dispatch_get_main_queue(), ^{block(-1);});
        }
    }
}


- (void)resetOutputTarget
{
    BOOL hasHeadset = [EAudioMisc hasHeadset];
    NSLog(@"Will Set output target is_headset = %@ .", hasHeadset ? @"YES" :@"NO");
    UInt32 audioRouteOverride = hasHeadset ?
kAudioSessionOverrideAudioRoute_None:kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride),&audioRouteOverride);
}


#pragma mark -- NSNotification --
- (void)applicationWillEnterForeground:(NSNotification*)notification
{
    NSLog(@"EAudioGraph: applicationWillEnterForeground");
    NSError *error = nil;
    if ( ![((AVAudioSession*)[AVAudioSession sharedInstance]) setActive:YES error:&error] ) {
        NSLog(@"TAAE: Couldn't activate audio session: %@", error);
    }
    
    if ( _interrupted ) {
        _interrupted = NO;
        
        [self restartInteranl];
    }
}


- (void)interruptionNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue] == AVAudioSessionInterruptionTypeEnded ) {
            NSLog(@"interruptionNotification: AVAudioSessionInterruptionTypeEnded");
            _interrupted = NO;
            
            if ( [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground || _started ) {
                // make sure we are again the active session
                NSError *error = nil;
                if ( ![((AVAudioSession*)[AVAudioSession sharedInstance]) setActive:YES error:&error] ) {
                    NSLog(@"EAudioGraph: Couldn't activate audio session: %@", error);
                }
            }
            [self restartInteranl];
            
        } else if ( [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue] == AVAudioSessionInterruptionTypeBegan ) {
            NSLog(@"interruptionNotification: AVAudioSessionInterruptionTypeBegan");
            if ( _interrupted ) return;
            
            _interrupted = YES;
            [self stopInternal];
            
            UInt32 iaaConnected;
            UInt32 size = sizeof(iaaConnected);
            AudioUnitGetProperty(_outputNode.audioUnit, kAudioUnitProperty_IsInterAppConnected, kAudioUnitScope_Global, 0, &iaaConnected, &size);
            if ( iaaConnected ) {
                NSLog(@"TAAE: Audio session interrupted while connected to IAA, restarting");
                [self restartInteranl];
                return;
            }
            
            //  [[NSNotificationCenter defaultCenter] postNotificationName:AEAudioControllerSessionInterruptionBeganNotification object:self];
            
            // processPendingMessagesOnRealtimeThread(self);
        }else{
            NSLog(@"interruptionNotification: unknow interruped.");
        }
    });
}

- (void)audioRouteChangeNotification:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( _interrupted || ![self isRunning] ) return;
        
        int reason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] intValue];
        if ( reason == AVAudioSessionRouteChangeReasonNewDeviceAvailable || reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable  ) {
            NSLog(@"audioRouteChangeNotification:AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            [self resetOutputTarget];
        }
    });
}

- (void)mediaServiceResetNotification:(NSNotification*)notification
{
    NSLog(@"EAudioGraph::mediaServiceResetNotification");
}

#pragma mark -AudioUnitAddRenderNotify-
static OSStatus audioUnitRenderCallback(void* inRefCon,
                                        AudioUnitRenderActionFlags *	ioActionFlags,
                                        const AudioTimeStamp *			inTimeStamp,
                                        UInt32							inBusNumber,
                                        UInt32							inNumberFrames,
                                        AudioBufferList * 	ioData)
{
    
    BOOL isPostRender = (*ioActionFlags & kAudioUnitRenderAction_PostRender);
    if (!isPostRender) { return noErr; }
    
    EAudioGraph* graph = (__bridge EAudioGraph *)(inRefCon);
    if (graph && graph.renderCB) {
        graph.renderCB(inNumberFrames,ioData);
    }
    
    return noErr;
}

@end

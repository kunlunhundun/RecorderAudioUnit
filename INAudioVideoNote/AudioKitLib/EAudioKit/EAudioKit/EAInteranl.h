//
//  EAudioGraph.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioGraph.h"
#import "EAudioFeeder.h"
typedef struct callback_t
{
    void *inRefCon;
    bool isValid;
}callback_info;

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////EAudioNode//////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
@interface EAudioNode ()

@property (nonatomic,assign)    AUGraph graph;

-(instancetype)initWithNode:(AUGraph)graph withNode:(AUNode)node withName:(NSString*)name;

-(void)onNodeConnected:(EAudioNode*)target isConnectToTargetOutput:(BOOL)isConnectToTargetOutput;

@end

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////EAudioSpot//////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
@class EAudioFile;
@class EAudioNodeRecorder;
@class EAMicrophone;
@class EAudioRenderBufferRecorder;
@class EAudioFileRecorder;

#define CUSTOMER_REVERB

#ifdef CUSTOMER_REVERB
@class auraReverb;
#endif

@class EAPitchDetector;
@class EAAudioPitch;
@class EAAudioPitchSyn;
@class EAudioPcmFile;
@class EACircleBuffer;
@class auraLimiter;

typedef void (^BlockTask)(void);

typedef void (^BaseOffsetBlockTask)(void);


@interface EAudioSpot()
{
    NSMutableDictionary* _nodeDictionary;
    
    EAudioNode*         _reverbNode;
    EAudioNode*         _eqNode;
    EAudioNode*         _micNode;
    EAMicrophone*       _microphone;
    BOOL                _hasConnectSpot;
    callback_info*      _callbackInfo;
    AudioStreamBasicDescription _audioSourceFormat;
    UInt64              _frameOffset;
    UInt64              _totalFrames;

    bool                _isReady;
    float               _curCustomGain;
    BOOL                _shouldNotifyBegin,_shouldNotifyEnd;
    BOOL                _allowFeedbackMicAudio;
    EACircleBuffer*     _channelDelayBuffer;//左右聲音延時，//產生立體聲
    int                 _delayDelayOffsetFrame,_channelDelayFrameOffsetRequire;
    id<EAudioFeeder>    _audioFileFeeder;
    EAudioFile*         _audioFile;
    EAudioFile*         _audioFileNew;
    EAPitchDetector*    _pitchDetector;
    auraLimiter*        _limiter;
    EAudioNodeRecorder* _recorder;             //錄製輸出的聲音
    EAudioFileRecorder*  _continueRecord;  //绪录音 重新打个录音文件然后继续录音
    EAudioRenderBufferRecorder* _bufferRecorder; //錄製音源的聲音
    EAudioPcmFile* _rawRecorder;
    BOOL           _isPauseRowRecordForPlay;     //true : 在试听阶段  no : 在录音阶段
    NSMutableArray*     _taskArray;
    NSMutableArray*     _baseOffsetTaskArray;
    
    NSTimeInterval      _curtimeRequire;//用戶拖拉了播放進度，延時更新
    
#ifdef CUSTOMER_REVERB
    auraReverb*                 _auraReverb; //自定義混音
#endif
    EAAudioPitch*               _pitchProcess;
    EAAudioPitchSyn*            _pitchProcessSyn;
}
@property (nonatomic,assign) EAudioGraph*            graph;
@property (nonatomic,assign) BOOL                  autoConfigASBD;
@property (nonatomic,strong)    EAudioNode* headNode;
@property (nonatomic,strong)    EAudioNode* tailNode;
@property (nonatomic,assign)    int          index;

-(instancetype)initWithGraph:(EAudioGraph*)graph withName:(NSString*)lineName Index:(int)index
;

-(void)createAudioSource:(NSString*)audioFile
         withAudioFormat:(AudioStreamBasicDescription)clientFormat
         GraphRenderType:(EAGraphRenderType)type;
-(void)createMicAudioSource:(AudioStreamBasicDescription)clientFormat
            GraphRenderType:(EAGraphRenderType)type;

-(void)onSpotConnectChanged:(BOOL)connected;
-(void)onAudioGraphDestroyed;
-(void)setCurrentTimeInternal:(NSTimeInterval) v;

-(OSStatus)feedAudioBuffer:(AudioUnitRenderActionFlags*)ioActionFlags
            AudioTimeStamp:(const AudioTimeStamp*)inTimeStamp
               inBusNumber:(UInt32)inBusNumber
            inNumberFrames:(UInt32)inNumberFrames
           AudioBufferList:(AudioBufferList*)ioData;
@end


@interface EAudioGraph()
{
    BOOL                _interrupted,_started;
    EAudioNode*         _mixNode;
    EAudioNode*         _ioNode;
    EAudioNode*         _genericNode;
    EAudioNode*         _outputNode;
    EAudioNode*         _lastEffectNode;
    EAudioNode*         _reverbNode;
    EAudioNode*         _eqNode;
    NSMutableArray*      _audioSpots;
    NSTimeInterval      _offsetRequire;
    EAudioNodeRecorder* _recorder;
    BOOL                 _offlineRendering;
    BOOL                 _interruptOfflineRender;
    AudioStreamBasicDescription _micAudioFormat;
    AudioStreamBasicDescription _defaultStreamFormat;
}
-(void)setCurrentTimeInternal:(NSTimeInterval)time;
@end


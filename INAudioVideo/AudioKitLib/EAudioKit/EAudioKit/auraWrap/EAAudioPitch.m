//
//  EAAudioBufferAsyReader.m
//  EAudioKit
//
//  Created by cybercall on 15/8/10.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "EAAudioPitch.h"
#import "EAudioFile.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "platform.h"
#import "aura.h"
#import "EAudioMisc.h"
#import "EAMicro.h"



@interface EAAudioPitch()
{
    
    TPCircularBuffer*            _audioTPbuffer1;
    TPCircularBuffer*            _audioTPbuffer2;
     AudioStreamBasicDescription _audioFormat;

    UInt32                       _bufferSize;
    UInt32                       _bufferFrameCount;
    aura::PitchShifter*          _pitchShifter;
    BOOL                         _isAudioFileEnd;
    char*                        _tempBuffer;
    AudioBufferList*             _bufferTempList;
    NSObject*                    _audioBufferLock1;
    NSObject*                    _audioBufferLock2;

    int                          _pitchValue;
    int                          _pitchRequire;
    //dispatch_queue_t             _pitchQueue;
    BOOL                         _bReady;
//    BOOL                         _preProcessPitching;
    int                          _sampleType;
    UInt32                       _delayFrameCount;
    NSOperationQueue*            _operationQueue;
   
    UInt32                       _offerIn,_recvOut;
    
}

@property (nonatomic,strong)   EAudioFile*    audioFile;

@end



@implementation EAAudioPitch

-(instancetype)initWithAudioFile:(NSTimeInterval)bufferTime
                     audioFormat:(AudioStreamBasicDescription)format
                       audioFile:(EAudioFile*)audioFile
{
    self = [super init];
    [self interanlInit:bufferTime audioFormat:format audioFile:audioFile];
    MARK_INSTANCE();
    return self;
}

-(instancetype)initWithAudioPath:(NSTimeInterval)bufferTime
                     audioFormat:(AudioStreamBasicDescription)format
                       audioFile:(NSString*)path
{
    
    self = [super init];
    
    _audioFormat = format;
    EAudioFile* audio = [[EAudioFile alloc]init];
    BOOL suc = [_audioFile openAudioFile:path withAudioDescription:format];
    if (suc){
        [self interanlInit:bufferTime audioFormat:format audioFile:audio];
    }
    MARK_INSTANCE();
    return self;
}

-(void)interanlInit:(NSTimeInterval)bufferTime
                     audioFormat:(AudioStreamBasicDescription)format
                      audioFile:(EAudioFile*)audioFile
{

    _audioFormat = format;
    self.audioFile = audioFile;
    _bReady = NO;
    _isAudioFileEnd = NO;
    if (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved)
    {
        if (bufferTime < 1) {
            bufferTime = 1;
        }
        //bufferTime = 10* bufferTime;
        _bufferFrameCount = bufferTime * format.mSampleRate;
        
        _bufferSize = _bufferFrameCount * format.mBytesPerFrame;
        _tempBuffer = (char*)malloc(_bufferSize);
        
        _bufferTempList = allocAudioBufferList(format,_bufferFrameCount);
        
        
        _audioBufferLock1 = [[NSObject alloc] init];
        _audioBufferLock2 = [[NSObject alloc] init];

        _audioTPbuffer1 = (TPCircularBuffer*)malloc(sizeof(TPCircularBuffer));
        _audioTPbuffer2 = (TPCircularBuffer*)malloc(sizeof(TPCircularBuffer));

        TPCircularBufferInit(_audioTPbuffer1, _bufferSize * 2 );
        TPCircularBufferInit(_audioTPbuffer2, _bufferSize * 2);
        
        _pitchRequire = 0;
        _pitchValue = 0;
        
        _sampleType = getAudioFormatType(format);
        
        [self createPitcher];
    }

    _operationQueue = [[NSOperationQueue alloc]init];
    _operationQueue.maxConcurrentOperationCount = 1;
    _operationQueue.name = @"audio_pitch_proc_queue";
    //setQualityOfService
    if ([_operationQueue respondsToSelector:@selector(setQualityOfService:)]) {
        _operationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    
    //_pitchQueue = dispatch_queue_create("audio_pitch_proc_queue", 0);
    
    //初始化数据，并通知onReady
    NSLog(@"EAudioPitch prepare pitch data begin...");
    [_operationQueue addOperationWithBlock:^{
        [self preProcessAudioData:_audioTPbuffer1 lock:_audioBufferLock1];
        [self preProcessAudioData:_audioTPbuffer2 lock:_audioBufferLock2];
        _bReady = YES;
        if (self.onReady != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"EAudioPitch prepare pitch data end...");
                self.onReady();
            });
        }

    }];
    
}

-(void)setOnReady:(void (^)())onReady
{
    if (self.onReady == nil && _bReady) {
        dispatch_async(dispatch_get_main_queue(), ^{
            onReady();
        });
    }
    _onReady = onReady;
}

-(void)createPitcher
{
    if (_pitchShifter) {
        _pitchShifter->Close();
        _pitchShifter = NULL;
    }
   
    int auraSampeType = -1;
    if( _sampleType == SAMPLE_TYPE_flOAT) {
        auraSampeType = aura::SampleType::FLOAT_SAMPLE;
    }else if (_sampleType == SAMPLE_TYPE_INT32) {
        auraSampeType = aura::SampleType::SHORT_SAMPLE;//8.24->16
    }else if(_sampleType == SAMPLE_TYPE_INT16){
        auraSampeType = aura::SampleType::SHORT_SAMPLE;
    }
    
    if (_sampleType != SAMPLE_TYPE_UNKNOW) {
        _pitchShifter = aura::CreatePitchShifter(_audioFormat.mSampleRate, _audioFormat.mChannelsPerFrame,auraSampeType);
    }
}

-(void)dealloc
{
    NSLog(@"Eaaudiopitch dealloc\n");
    [self close];
    UNMARK_INSTANCE();
}

-(void)setPitch:(int)pitch
{
    if (!(_audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved))
    {
        _pitchValue = 0;
        _pitchRequire = 0;
        NSLog(@"waring EAAudioPitch,setPitch,not support audio format!!!!");
        return;
    }
    
    if (pitch > 12) {
        pitch = 12;
    }
    if (pitch < -12) {
        pitch = -12;
    }
    if (pitch == _pitchValue) {
        return;
    }
    _pitchRequire = pitch;
    
    [_operationQueue addOperationWithBlock:^{
        int require = _pitchRequire;
        if (_pitchRequire != _pitchValue)
        {
            if(_pitchShifter){
                _pitchShifter->SetPitchSemiTones(require);
            }
            NSLog(@"pitch:%d->%d",_pitchValue,require);
            _pitchValue = require;
        }
    }];
}

-(BOOL)seekToFrame:(float)second
{
    //must be runned in audioPlayThread
    [_operationQueue cancelAllOperations];
    [_operationQueue waitUntilAllOperationsAreFinished];
    if(_pitchShifter){
        _pitchShifter->SetPitchSemiTones(_pitchValue);
    }

    _isAudioFileEnd = NO;
    [_audioFile seekToFrame:second];
    TPCircularBufferClear(_audioTPbuffer1);
    TPCircularBufferClear(_audioTPbuffer2);
    [self preProcessAudioData:_audioTPbuffer1 lock:_audioBufferLock1];
    [self preProcessAudioData:_audioTPbuffer2 lock:_audioBufferLock2];

    UInt32 frame1 = TPCircularBufferPeek(_audioTPbuffer1, NULL, &(_audioFormat));
    UInt32 frame2 = TPCircularBufferPeek(_audioTPbuffer2, NULL, &(_audioFormat));
    NSLog(@"pitch pre-process frames[%d|%d]",frame1,frame2);
    
    return YES;
}

-(void)close
{
    if (_operationQueue == nil)
        return;
    
    int taskCount = _operationQueue.operationCount;
    if (taskCount > 0) {
        NSLog(@"audioPitch %d task running,cancel all....",taskCount);
        [_operationQueue cancelAllOperations];
        [_operationQueue waitUntilAllOperationsAreFinished];
    }
    
    if (_pitchShifter) {
        _pitchShifter->Close();
        _pitchShifter = NULL;
    }
    
    if (_tempBuffer) {
        free(_tempBuffer);
        _tempBuffer = NULL;
    }
    
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
    
    if (_bufferTempList) {
        freeAudioBufferList(_bufferTempList);
        _bufferTempList = NULL;
    }
    NSLog(@"audioPitch closed");
    
}

-(void)setDelay:(float)second
{
    [_audioFile setDelay:second];
}

-(int)feedBufferList:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount
{
    
    TIME_SLAPS_TRACER("audioPitch,processPitch",0.005);
    int nRead = 0;
    
    //開始填充聲音數據
    UInt32 frame1 = frameCount;
    @synchronized(_audioBufferLock1) {
        TIME_SLAPS_TRACER("audioPitch,processPitch_inner_lock1",0.005);
        TPCircularBufferDequeueBufferListFrames(_audioTPbuffer1,
                                                &frame1,
                                                bufferList,
                                                NULL,
                                                &_audioFormat);
    }
    nRead = frame1;
    if (frame1 < frameCount)
    {
        UInt32 frame2 = frameCount - frame1;
        @synchronized(_audioBufferLock2) {
            TIME_SLAPS_TRACER("audioPitch,processPitch_inner_lock2",0.005);
            
            char temp[sizeof(AudioBufferList) + sizeof(AudioBuffer)];
            AudioBufferList* wrap = monitorBufferList(temp, bufferList, frame1, _audioFormat.mBytesPerFrame);
            TPCircularBufferDequeueBufferListFrames(_audioTPbuffer2,
                                                &frame2,
                                                wrap,
                                                NULL,
                                                &_audioFormat);
      
        }
        nRead += frame2;
        TPCircularBuffer* tmp = _audioTPbuffer2;
        _audioTPbuffer2 = _audioTPbuffer1;
        _audioTPbuffer1 = tmp;
        
        NSObject* objTmp = _audioBufferLock1;
        _audioBufferLock1 = _audioBufferLock2;
        _audioBufferLock2 = objTmp;
        
        [_operationQueue addOperationWithBlock:^{
            [self preProcessAudioData:_audioTPbuffer2 lock:_audioBufferLock2];
        }];
        
    }
    
    if (nRead < frameCount && !_isAudioFileEnd) {
        NSLog(@"AEudioPitch,feedBufferList,waitting for pitch data....");
        [_operationQueue waitUntilAllOperationsAreFinished];
        
        char temp[sizeof(AudioBufferList) + sizeof(AudioBuffer)];
        AudioBufferList* wrap = monitorBufferList(temp, bufferList, nRead, _audioFormat.mBytesPerFrame);
        int read2 = [self feedBufferList:wrap frameCount:(frameCount - nRead) ];
        nRead += read2;
        NSLog(@"AEudioPitch,feedBufferList,waitting end....");
    }
    
#if DEBUG
    if(nRead != frameCount && !_isAudioFileEnd)
        NSLog(@"pitch-feedBufferList,require:%d,return:%d",frameCount,nRead);
#endif

    return nRead;
}

-(void)offer:(AudioBufferList*)audioBufferList FrameCount:(int)samples shouldFlush:(BOOL)flush
{
    
    if (_pitchShifter)
    {
        if (samples > 0 && audioBufferList )
        {
            void* inputs[2] = {audioBufferList->mBuffers[0].mData,audioBufferList->mBuffers[1].mData};
            if( _sampleType == SAMPLE_TYPE_flOAT ||
               _sampleType == SAMPLE_TYPE_INT16)
            {

                _pitchShifter->Offer((const void**)inputs, samples);
            }else if (_sampleType == SAMPLE_TYPE_INT32)
            {
                //conver 8.24 to int16
                fixedPointToSInt16((SInt32 *) audioBufferList->mBuffers[0].mData,
                                   (SInt16 *)_tempBuffer, samples );
                fixedPointToSInt16((SInt32 *) audioBufferList->mBuffers[1].mData,
                                   (SInt16 *)audioBufferList->mBuffers[0].mData, samples );
                
                _pitchShifter->Offer((const void**)inputs, samples);
                
            }
        }
        _offerIn += samples;
        if (flush) {
            _pitchShifter->Flush();
        }
    }
    
}

-(int)receive:(AudioBufferList*)audioBufferList MaxFrame:(int)maxFrame
{
    UInt32 availables = _pitchShifter->Available();
 
    int avail = MIN(maxFrame, availables);
    if (avail <= 0 ) {
        return 0;
    }
    
    void* inputs[2] = {audioBufferList->mBuffers[0].mData,audioBufferList->mBuffers[1].mData};
    
    if( _sampleType == SAMPLE_TYPE_flOAT ||
       _sampleType == SAMPLE_TYPE_INT16)
    {
        UInt32 recv = _pitchShifter->Receive(inputs, avail);
        assert(recv == avail);
        
    }else if (_sampleType == SAMPLE_TYPE_INT32)
    {
        _pitchShifter->Receive(inputs, avail);
        //cover int16 to 8.24
        SInt16ToFixedPoint((SInt16 *)audioBufferList->mBuffers[0].mData, (SInt32 *)_tempBuffer, avail );
        SInt16ToFixedPoint((SInt16 *)audioBufferList->mBuffers[1].mData, (SInt32 *)audioBufferList->mBuffers[0].mData, avail );
        memcpy(audioBufferList->mBuffers[1].mData, _tempBuffer, audioBufferList->mBuffers[1].mDataByteSize);
    }
    _recvOut += avail;
    return avail;
}

-(int)flushPitchCacheData:(TPCircularBuffer*)audioTPbuffer lock:(NSObject*)lock
{
    [self offer:NULL FrameCount:0 shouldFlush:YES];
    
    int frames = 0;
    int framesRecv = 0;
    do{
        framesRecv = [self receive:_bufferTempList MaxFrame:_bufferFrameCount];
        if (framesRecv > 0) {
            @synchronized(lock) {
                if (_recvOut > _offerIn){
                    int off = _recvOut - _offerIn;
                    NSLog(@"warning,EAAudioPitch->(_recvOut > _offerIn ->%d) !!!",off);
                    framesRecv -= (_recvOut - _offerIn);
                }
                TPCircularBufferCopyAudioBufferList(audioTPbuffer,_bufferTempList,NULL,framesRecv,&(_audioFormat));
            }
            frames += framesRecv;
        }
    }while (framesRecv > 0);
    
    if (_recvOut < _offerIn) {
        int off = _offerIn - _recvOut;
        NSLog(@"warning,EAAudioPitch->(_recvOut < _offerIn ->%d) !!!",off);
        _offerIn = _recvOut = 0;
        
        [EAudioMisc fillSilence:_bufferTempList];
        @synchronized(lock) {
            TPCircularBufferCopyAudioBufferList(audioTPbuffer,_bufferTempList,NULL,off,&(_audioFormat));
        }
        
    }
    return frames;
}

-(void)preProcessAudioData:(TPCircularBuffer*)audioTPbuffer lock:(NSObject*)lock
{
    if (_isAudioFileEnd) {
        return;
    }
    
    if ( _pitchValue == 0)
    {
        //不需要变调，强制让它flush出所有数据
        int framesRecv = [self flushPitchCacheData:audioTPbuffer lock:lock];
        
        int frame = _bufferFrameCount - framesRecv;
        if (frame > 0) {
            int nRead = [_audioFile feedBufferList:_bufferTempList frameCount:frame];
            if (nRead > 0) {
                @synchronized(lock) {
                    TPCircularBufferCopyAudioBufferList(audioTPbuffer,_bufferTempList,NULL,nRead,&(_audioFormat));
                }
            }
            if (nRead != frame) {
                _isAudioFileEnd = YES;
            }
        }
        return;
    }
    

    int nFramePitch = 0;
    do{
        int nFrameCanFeed = TPCircularBufferGetAvailableSpace(audioTPbuffer, &_audioFormat);
        int nFrame = MIN(nFrameCanFeed, _bufferFrameCount);
        int nRead = [_audioFile feedBufferList:_bufferTempList frameCount:nFrame];
        if ( nRead > 0 )
        {
            int samples = nRead;
            [self offer:_bufferTempList FrameCount:samples shouldFlush:NO];
            int framesRecv = [self receive:_bufferTempList MaxFrame:nFrame];
            
            if (framesRecv > 0) {
                @synchronized(lock) {
                    TPCircularBufferCopyAudioBufferList(audioTPbuffer,_bufferTempList,NULL,framesRecv,&(_audioFormat));
                    nFramePitch += framesRecv;
                }
            }
        }
        if (nRead != nFrame)
        {
            [self flushPitchCacheData:audioTPbuffer lock:lock];
            _isAudioFileEnd = YES;
            break;
        }
    }while(nFramePitch < _bufferFrameCount);
}

@end



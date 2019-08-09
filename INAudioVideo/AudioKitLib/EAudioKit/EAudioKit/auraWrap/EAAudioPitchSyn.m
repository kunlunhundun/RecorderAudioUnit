//
//  EAAudioBufferAsyReader.m
//  EAudioKit
//
//  Created by cybercall on 15/8/10.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "EAAudioPitchSyn.h"
#import "EAudioFile.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "platform.h"
#import "aura.h"
#import "EAudioMisc.h"
#import "EAMicro.h"


#define INVALID_PITCH_VALUE 0xff

@interface EAAudioPitchSyn()
{

     AudioStreamBasicDescription _audioFormat;
    UInt64                       _totalFrameShouldOffer;
    UInt64                       _frameOffers;
    UInt32                       _bufferSize;
    UInt32                       _bufferFrameCount;
    aura::PitchShifter*          _pitchShifter;
    char*                        _tempBuffer;
    AudioBufferList*             _bufferTempList;
    
    int                          _pitchValue;

    BOOL                         _bReady;
    int                          _sampleType;
    
    UInt32                       _delay;
    
}

@property (nonatomic,strong)   EAudioFile*    audioFile;

@end



@implementation EAAudioPitchSyn

-(instancetype)initWithAudioFile:(AudioStreamBasicDescription)format
                       audioFile:(EAudioFile*)audioFile
{
    self = [super init];
    [self interanlInit:format audioFile:audioFile];
    MARK_INSTANCE();
    return self;
}

-(instancetype)initWithAudioPath:(AudioStreamBasicDescription)format
                       audioFile:(NSString*)path
{
    
    self = [super init];
    
    _audioFormat = format;
    EAudioFile* audio = [[EAudioFile alloc]init];
    BOOL suc = [_audioFile openAudioFile:path withAudioDescription:format];
    if (suc){
        [self interanlInit:format audioFile:audio];
    }
    MARK_INSTANCE();
    return self;
}

-(void)interanlInit:(AudioStreamBasicDescription)format
                      audioFile:(EAudioFile*)audioFile
{

    _audioFormat = format;
    self.audioFile = audioFile;
    _bReady = NO;
    _pitchValue = INVALID_PITCH_VALUE;
    if (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved)
    {
        _bufferFrameCount = format.mSampleRate * 1.0 ;
        _bufferSize = _bufferFrameCount * format.mBytesPerFrame;
        _tempBuffer = (char*)malloc(_bufferSize);
        
        _bufferTempList = allocAudioBufferList(format,_bufferFrameCount);
        
        _sampleType = getAudioFormatType(format);
        
        _frameOffers = 0;
        _totalFrameShouldOffer = audioFile.audioFrameCount;
        [self createPitcher];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onReady();
    });
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
    [self close];
    UNMARK_INSTANCE();
}

-(void)setPitch:(int)pitch
{
    if (pitch > 12) {
        pitch = 12;
    }
    if (pitch < -12) {
        pitch = -12;
    }
    if(_pitchValue != INVALID_PITCH_VALUE){
        NSLog(@"warning!!!,not support to change pitch value!");
        return;
    }
    _pitchValue = pitch;
    
    if(_pitchShifter){
        _pitchShifter->SetPitchSemiTones(_pitchValue);
    }
}

-(void)close
{
    if (_pitchShifter) {
        _pitchShifter->Close();
        _pitchShifter = NULL;
    }
    
    if (_tempBuffer) {
        free(_tempBuffer);
        _tempBuffer = NULL;
    }
    if (_bufferTempList) {
        freeAudioBufferList(_bufferTempList);
        _bufferTempList = NULL;
    }
}

-(BOOL)seekToFrame:(float)second
{
    [_audioFile seekToFrame:second];
    return YES;
}

-(void)setDelay:(float)second
{
    _delay = second * _audioFormat.mSampleRate;
    if (_delay < 0 ) {
        _delay = 0;
    }
}

-(int)feedDelayAudioData:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount
{
    //需要延時，先處理延時
    if (_delay > 0)
    {
        [EAudioMisc fillSilence:bufferList];
        if (_delay >= frameCount) {
            _delay -= frameCount;
            return frameCount;
        }else
        {
            char temp[sizeof(AudioBufferList)+sizeof(AudioBuffer)];
            AudioBufferList* wrap = monitorBufferList(temp, bufferList, _delay, _audioFormat.mBytesPerFrame);
            
            int frame1 = _delay;
            int frame = frameCount - frame1;
            _delay = 0;
            int frame2 = [self feedBufferList:wrap frameCount:frame];
            return (frame1 + frame2);
        }
    }
    return 0;
}

-(int)feedBufferList:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount;
{
    //需要延時，先處理延時
    if (_delay > 0)
    {
        int frame = [self feedDelayAudioData:bufferList frameCount:frameCount];
        return frame;
    }
    
    if (_pitchValue == 0 || _pitchValue == INVALID_PITCH_VALUE)
    {
         int nRead = [_audioFile feedBufferList:bufferList frameCount:frameCount];
        return nRead;
    }

    int nFrame = [self procAudioData:bufferList FrameCount:frameCount];
    return nFrame;
}

-(void)offer:(AudioBufferList*)audioBufferList FrameCount:(int)samples
{
    
    void* inputs[2] = {audioBufferList->mBuffers[0].mData,audioBufferList->mBuffers[1].mData};
    if (samples > 0 && audioBufferList )
    {
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
}

-(int)receive:(AudioBufferList*)audioBufferList MaxFrame:(int)maxFrame
{
    void* inputs[2] = {audioBufferList->mBuffers[0].mData,audioBufferList->mBuffers[1].mData};;

    int avail = _pitchShifter->Available();
    avail = MIN(maxFrame, avail);
    if (avail <= 0 ) {
        return 0;
    }

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
        memcpy(audioBufferList->mBuffers[1].mData, _tempBuffer, avail * _audioFormat.mBytesPerFrame);
    }
    
    return avail;
}

-(void)flush
{
    if (_pitchShifter) {
        _pitchShifter->Flush();
    }
}


-(int)procAudioData:(AudioBufferList*)outputBufferList FrameCount:(int)frameCount
{
    
    int nFramePitch = 0;
    int frameRequire = frameCount;
    int frame = MIN(_bufferFrameCount, frameCount);
    char temp[sizeof(AudioBufferList)+sizeof(AudioBuffer)];
    BOOL bEnd = NO;
    AudioBufferList* audioBufferList = monitorBufferList(temp,outputBufferList,nFramePitch,_audioFormat.mBytesPerFrame);
    do{
        int nRead = [_audioFile feedBufferList:_bufferTempList frameCount:frame];
        if ( nRead > 0  )
        {
            _frameOffers += nRead;
            [self offer:_bufferTempList FrameCount:nRead];
        }
        
        if (_frameOffers == _totalFrameShouldOffer || nRead != frame) {
            [self flush];
            bEnd = YES;
            _frameOffers = _totalFrameShouldOffer;
        }
        
        int framesRecv = [self receive:audioBufferList MaxFrame:frameRequire];
        
        if (framesRecv > 0)
        {
            nFramePitch += framesRecv;
            frameRequire -= framesRecv;
            audioBufferList = monitorBufferList(temp,outputBufferList,nFramePitch,_audioFormat.mBytesPerFrame);
        }
        
    }while(nFramePitch < frameCount && !bEnd);
    
    if (nFramePitch < frameCount) {
        audioBufferList = monitorBufferList(temp,outputBufferList,nFramePitch,_audioFormat.mBytesPerFrame);
        [EAudioMisc fillSilence:audioBufferList];
    }
    
    return frameCount;
}

@end



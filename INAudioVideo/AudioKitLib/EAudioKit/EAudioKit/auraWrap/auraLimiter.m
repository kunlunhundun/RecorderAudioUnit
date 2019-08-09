//
//  auraWrap.m
//  AudioTest
//
//  Created by cybercall on 15/7/16.
//  Copyright © 2015年 rcshow. All rights reserved.
//
#import "platform.h"
#import "auraLimiter.h"
#import "aura.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

#import "EAudioMisc.h"
#import "EAMicro.h"


#define INVALID_OPT 0xFFFFFF

#define FLOAT_BUFFER_COUNT  1024 * 8 * sizeof(float)


@interface auraLimiter()
{

    aura::Limiter*  _limiter;

    char*          _tempBuffer;
    AudioStreamBasicDescription _audioSourceFormat;
    AuraReverbPresent _reverbPresentRunning;
    float             _reverbOpts[AuraReverbOption_MAX];
    BOOL              _reverbOptChanged;
    int               _sampleType;
}
@end

@implementation auraLimiter

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription) audioSourceFormat
{
    self = [super init];

    _sampleType = SAMPLE_TYPE_UNKNOW;
    [self createReverb:audioSourceFormat];
    return self;
}
-(void)dealloc
{
    if (_limiter) {
        _limiter->Close();
        _limiter = NULL;
    }
    
    if (_tempBuffer) {
        free(_tempBuffer);
        _tempBuffer = NULL;
    }
}

-(void)createReverb:(AudioStreamBasicDescription) audioSourceFormat
{
    
    if(audioSourceFormat.mFormatID != kAudioFormatLinearPCM)
        return;
    //kAudioFormatFlagIsFloat
    if(0 == (audioSourceFormat.mFormatFlags  & kAudioFormatFlagIsNonInterleaved) ){
        NSLog(@"auraReverb,audioSourceFormat not support!!!!");
        return;
    }
    
    _audioSourceFormat = audioSourceFormat;
    UInt32 sampleRate = _audioSourceFormat.mSampleRate;
    
    _sampleType = getAudioFormatType(audioSourceFormat);
    int auraSampeType = -1;
    if( _sampleType == SAMPLE_TYPE_flOAT) {
        auraSampeType = aura::SampleType::FLOAT_SAMPLE;
    }else if (_sampleType == SAMPLE_TYPE_INT32) {
        auraSampeType = aura::SampleType::SHORT_SAMPLE;//8.24->16
    }else if(_sampleType == SAMPLE_TYPE_INT16){
        auraSampeType = aura::SampleType::SHORT_SAMPLE;
    }
    
    if (_sampleType != SAMPLE_TYPE_UNKNOW) {
        _limiter = aura::CreateLimiter(sampleRate,2,auraSampeType);
        _tempBuffer = (char*)malloc(FLOAT_BUFFER_COUNT);
        
        if(_sampleType == SAMPLE_TYPE_flOAT){
            float ceiling = 0.8;
            _limiter->SetOption(aura::LimiterOption::CEILING, ceiling);
            _limiter->SetOption(aura::LimiterOption::THRESHOLD, ceiling/2);
        }
    }
}

-(void)process:(AudioBufferList*)ioData
{

    if(0 == (_audioSourceFormat.mFormatFlags  & kAudioFormatFlagIsNonInterleaved))
        return;
    
    TIME_SLAPS_TRACER("auraLimiter,process audioBufferList",0.1);

    
    void* inputs[2] = {ioData->mBuffers[0].mData,ioData->mBuffers[1].mData};
    int samples = ioData->mBuffers[0].mDataByteSize/_audioSourceFormat.mBytesPerFrame;
    if(_sampleType == SAMPLE_TYPE_INT16 ||
       _sampleType == SAMPLE_TYPE_flOAT)
    {
        _limiter->Process((const void**)inputs, (void**)inputs, samples);

    }else if(_sampleType == SAMPLE_TYPE_INT32)
    {
        if (ioData->mBuffers[0].mDataByteSize > FLOAT_BUFFER_COUNT)
            return;
        
        //conver 8.24 to int16
        fixedPointToSInt16((SInt32 *) ioData->mBuffers[0].mData, (SInt16 *)_tempBuffer, samples );
        fixedPointToSInt16((SInt32 *) ioData->mBuffers[1].mData, (SInt16 *)ioData->mBuffers[0].mData, samples );
        memcpy(ioData->mBuffers[1].mData, _tempBuffer, samples * sizeof(SInt16));
        
        _limiter->Process((const void**)inputs, (void**)inputs, samples);

        //cover int16 to 8.24
        SInt16ToFixedPoint((SInt16 *) ioData->mBuffers[0].mData, (SInt32 *)_tempBuffer, samples );
        SInt16ToFixedPoint((SInt16 *) ioData->mBuffers[1].mData, (SInt32 *)ioData->mBuffers[0].mData, samples );
        memcpy(ioData->mBuffers[1].mData, _tempBuffer, ioData->mBuffers[1].mDataByteSize);
        
    }
    
}


@end

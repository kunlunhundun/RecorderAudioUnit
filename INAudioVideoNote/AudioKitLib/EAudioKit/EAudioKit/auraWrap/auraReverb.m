//
//  auraWrap.m
//  AudioTest
//
//  Created by cybercall on 15/7/16.
//  Copyright © 2015年 rcshow. All rights reserved.
//
#import "platform.h"
#import "auraReverb.h"
#import "aura.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

#import "EAudioMisc.h"
#import "EAMicro.h"


#define INVALID_OPT 0xFFFFFF

#define FLOAT_BUFFER_COUNT  1024 * 8 * sizeof(float)


@interface auraReverb()
{
    BOOL            _enable;
    aura::Reverber* _reverb;
    //aura::Reverber* _reverbLeft;
   // aura::Reverber* _reverbRight;
    char*          _tempBuffer;
    AudioStreamBasicDescription _audioSourceFormat;
    AuraReverbPresent _reverbPresentRunning;
    float             _reverbOpts[AuraReverbOption_MAX];
    BOOL              _reverbOptChanged;
    int               _sampleType;
}
@end

@implementation auraReverb

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription) audioSourceFormat
{
    self = [super init];
    _enable = false;
    _sampleType = SAMPLE_TYPE_UNKNOW;
    [self createReverb:audioSourceFormat];
    return self;
}
-(void)dealloc
{
    if (_reverb) {
        _reverb->Close();
        _reverb = NULL;
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
    
    _reverbPresent = AuraReverbPresent_NONE;
    _reverbPresentRunning = AuraReverbPresent_NONE;

    _audioSourceFormat = audioSourceFormat;
    UInt32 sampleRate = _audioSourceFormat.mSampleRate;
    int reverbType = [auraConfig defaultConfig].reverbType;
    
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
        _reverb = aura::CreateReverber(sampleRate,2,reverbType,auraSampeType);
        _tempBuffer = (char*)malloc(FLOAT_BUFFER_COUNT);
    }
}

-(void)setReverbPresent:(AuraReverbPresent)present
{
    if(_reverbPresent == present)
        return;
  
    _reverbPresent = present;
    NSLog(@"set reverb present idx:%ld",(long)present);

}

-(void)process:(AudioBufferList*)ioData
{

    if (!_enable){
        return;
    }
    if(0 == (_audioSourceFormat.mFormatFlags  & kAudioFormatFlagIsNonInterleaved))
        return;
    
    TIME_SLAPS_TRACER("auraReverb,process audioBufferList",0.1);

    if (_reverbOptChanged ) {
        _reverbOptChanged = NO;
        NSLog(@"reverb option changed");

        
        NSArray* ingoreArray = @[@0,@6,@7,@9,@10,@12,@13,@14,@15,@16,@17,@18,@19];
        NSSet* ingoreSet = [NSSet setWithArray:ingoreArray];
        for(int i = AuraReverbOption_BEGIN; i < AuraReverbOption_MAX; i++)
        {
            if (_reverb)
            {
            
                if ([ingoreSet containsObject: [NSNumber numberWithInteger:i]] ) {
                    continue;
                }
                float v2  = _reverbOpts[i];
#if DEBUG
                float v1 = 0;
                _reverb->GetOption(i, v1);
                NSLog(@"%02d: %0.3f -> %0.3f",i,v1,v2);
#endif
                _reverb->SetOption(i, v2);
            }
        }
        if (_reverb) {
            _reverb->Reset();
        }
    }
    
    void* inputs[2] = {ioData->mBuffers[0].mData,ioData->mBuffers[1].mData};
    int samples = ioData->mBuffers[0].mDataByteSize/_audioSourceFormat.mBytesPerFrame;
    if(_sampleType == SAMPLE_TYPE_INT16 ||
       _sampleType == SAMPLE_TYPE_flOAT)
    {
        _reverb->Process((const void**)inputs, (void**)inputs, samples);

    }else if(_sampleType == SAMPLE_TYPE_INT32)
    {
        if (ioData->mBuffers[0].mDataByteSize > FLOAT_BUFFER_COUNT)
            return;
        
        //conver 8.24 to int16
        fixedPointToSInt16((SInt32 *) ioData->mBuffers[0].mData, (SInt16 *)_tempBuffer, samples );
        fixedPointToSInt16((SInt32 *) ioData->mBuffers[1].mData, (SInt16 *)ioData->mBuffers[0].mData, samples );
        memcpy(ioData->mBuffers[1].mData, _tempBuffer, samples * sizeof(SInt16));
        
        _reverb->Process((const void**)inputs, (void**)inputs, samples);

        //cover int16 to 8.24
        SInt16ToFixedPoint((SInt16 *) ioData->mBuffers[0].mData, (SInt32 *)_tempBuffer, samples );
        SInt16ToFixedPoint((SInt16 *) ioData->mBuffers[1].mData, (SInt32 *)ioData->mBuffers[0].mData, samples );
        memcpy(ioData->mBuffers[1].mData, _tempBuffer, ioData->mBuffers[1].mDataByteSize);
        
    }
    
}

-(void)saveReverbOption
{
    if (_reverb) {
        for(int i = AuraReverbOption_BEGIN; i < AuraReverbOption_MAX; i++)
        {
            float v = 0;
            _reverb->GetOption(i, v);
            _reverbOpts[i] = v ;
        }
    }
}

-(void)setReverbOption:(AuraReverbOption)opt Value:(float)v
{
    _reverbOpts[opt] = v;
    _reverbOptChanged = YES;
}

-(void)setReverbOpts:(float[AuraReverbOption_MAX])opts
{
    BOOL zero = YES;
    for (int i=0; i < AuraReverbOption_MAX; i++) {
        zero &= (opts[i] == 0);
    }
    if (zero) {
        _enable = NO;
    }else{
        _enable = YES;
        memcpy(_reverbOpts, opts, sizeof(float)*AuraReverbOption_MAX);
        _reverbOptChanged = YES;
    }
}

-(float)getReverbOption:(AuraReverbOption)opt
{
    return _reverbOpts[opt] ;
}

@end

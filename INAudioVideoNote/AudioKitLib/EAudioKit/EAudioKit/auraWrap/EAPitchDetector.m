//
//  EAPitchDetector.m
//  EAudioKit
//
//  Created by cybercall on 15/7/28.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "EAPitchDetector.h"
#import <Accelerate/Accelerate.h>
#import "EAMicro.h"
#import "platform.h"
#import "aura/aura.h"
#import "EAudioMisc.h"
#import "EAMicro.h"
#import "auraConfig.h"

#define MAX_FRAMES          2048
#define BUFFER_CAPACITY     (MAX_FRAMES * sizeof(float))

#define ENABLE_PITCH_DETECTOR    1
#define ENABLE_OFFER_DATA        1
#define ENABLE_GET_PITCH         1

@interface EAPitchDetector()
{
    aura::PitchDetector* _detector;
   // ThreadLoop*          _threadLoop;
    BOOL                 _waitingPitchCalc;
    UInt32               _lastFreqSamplePos;//上一次更新_frequency時的sample位置
    UInt32               _sampleTotalInput; //總共輸入進入來的sample數
    UInt32               _sampleCountFeeded,_sampleMax;
    float _sampleRate;
    AudioStreamBasicDescription _audioFormat;
    dispatch_queue_t     _pitchCalcQueue;
    int                  _sampleType;
    char*                _tempBuffer;
}
@end

@implementation EAPitchDetector


-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription)asbd
{
    self = [super init];
    _audioFormat = asbd;
    _sampleRate = asbd.mSampleRate;
    _frequency = 0;
    _detector = NULL;
    _tempBuffer = NULL;
    _sampleType = getAudioFormatType(asbd);
    if (asbd.mFormatFlags & (kAudioFormatFlagIsNonInterleaved))
    {
        
        int auraSampeType = -1;
        if( _sampleType == SAMPLE_TYPE_flOAT) {
            auraSampeType = aura::SampleType::FLOAT_SAMPLE;
        }else if (_sampleType == SAMPLE_TYPE_INT32) {
            auraSampeType = aura::SampleType::SHORT_SAMPLE;//8.24->16
            _tempBuffer = (char*)malloc(_sampleRate * 4);
        }else if(_sampleType == SAMPLE_TYPE_INT16){
            auraSampeType = aura::SampleType::SHORT_SAMPLE;
        }
        
        if (_sampleType != SAMPLE_TYPE_UNKNOW) {
#if ENABLE_PITCH_DETECTOR
            _detector = aura::CreatePitchDetector(_sampleRate,1,auraSampeType);
#endif
        }
    }
    _lastFreqSamplePos = 0;
    _sampleTotalInput = 0;
    _sampleCountFeeded = 0;
    _waitingPitchCalc = NO;
    float duration = [auraConfig defaultConfig].freqDetectDuration;
    _sampleMax = (UInt32)(_sampleRate * duration);
    
    _pitchCalcQueue = dispatch_queue_create("pitch_detector_thread.queue", 0);
    
    MARK_INSTANCE();
    return self;
}

-(void)dealloc
{
    UNMARK_INSTANCE();
    if (_detector) {
        _detector->Close();
        _detector = NULL;
    }
    if (_tempBuffer) {
        free(_tempBuffer);
        _tempBuffer = NULL;
    }

}

-(void)processPitch:(const AudioTimeStamp*)inTimeStamp
     inNumberFrames:(UInt32)inNumberFrames
    AudioBufferList:(AudioBufferList*)ioData
{

    if (!_detector) {
        return ;
    }
    assert(inNumberFrames <= ioData->mBuffers[0].mDataByteSize / _audioFormat.mBytesPerFrame);
    void* data = ioData->mBuffers[0].mData;
    UInt32 samples = inNumberFrames;//ioData->mBuffers[0].mDataByteSize / _audioFormat.mBytesPerFrame;
    
    _sampleTotalInput += inNumberFrames;
    if (_waitingPitchCalc){
        return;
    }
    
    if( _sampleType == SAMPLE_TYPE_flOAT || _sampleType == SAMPLE_TYPE_INT16) {
        _detector->Offer(data, samples);
    }else if (_sampleType == SAMPLE_TYPE_INT32) {
        //conver 8.24 to int16
        fixedPointToSInt16((SInt32 *) data,
                           (SInt16 *)_tempBuffer, samples );
        _detector->Offer(_tempBuffer, samples);
        
    }

    _sampleCountFeeded += samples;
    if (_sampleCountFeeded >= _sampleMax)
    {
        _sampleCountFeeded = 0;
        _waitingPitchCalc = YES;
        dispatch_async(_pitchCalcQueue, ^{
            float freq = 0;
#if ENABLE_GET_PITCH
            freq = _detector->GetPitch();
#endif
            if (freq == 0 && (_sampleTotalInput - _lastFreqSamplePos < _sampleRate *0.3 ))
            {
                /*頻率為0的話，又在0.3秒內，繼續使用上次的_frequency
                 *暫不更新_frequency的值
                 */
                if(_frequency != 0 ){
                    //NSLog(@"freq<--:%f",_frequency);
                }
            }else{
                _frequency = freq;
                _lastFreqSamplePos = _sampleTotalInput;
            }
            _waitingPitchCalc = NO;
            if (freq > 1 ) {
               // NSLog(@"freq:%f",freq);
            }
            ;
        });
    }
}

@end

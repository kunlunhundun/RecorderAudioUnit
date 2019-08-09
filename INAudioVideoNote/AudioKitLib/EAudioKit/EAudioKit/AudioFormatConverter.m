//
//  AudioFormatConverter.m
//  EAudioKit
//
//  Created by cybercall on 15/7/29.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "AudioFormatConverter.h"
#import "EAMicro.h"
#import "EAudioMisc.h"

#define BUFFER_SIZES (4*1024 * sizeof(float))

#define kxSignedIntNonInter (kAudioFormatFlagIsSignedInteger |kAudioFormatFlagIsNonInterleaved)


@interface AudioFormatConverter()
{
    AudioStreamBasicDescription _inFormat;
    AudioStreamBasicDescription _outFormat;
    AudioConverterRef           _converter;
    char*                       _outputBuffer;
    
}
@end


@implementation AudioFormatConverter


-(instancetype)init:(AudioStreamBasicDescription)inFormat outputFormat:(AudioStreamBasicDescription)outFormat
{
    self = [super init];
    _inFormat = inFormat;
    _outFormat = outFormat;
    
    _outputBuffer = (char*)malloc(BUFFER_SIZES);
    _converter = [self createConverter:inFormat outputFormat:outFormat];
    
    return self;
}

-(void)dealloc
{
    if (_converter) {
        AudioConverterDispose(_converter);
        _converter = NULL;
    }
    if (_outputBuffer) {
        free(_outputBuffer);
        _outputBuffer = NULL;
    }
}

-(AudioConverterRef)createConverter:(AudioStreamBasicDescription)inFormat outputFormat:(AudioStreamBasicDescription)outFormat
{
  //  NSLog(@"------------------AudioFormatConverter----------------\nfrom:%@\nto:\n%@\n\n",
  //        [AudioStreamBasicDescriptions formatASBD:inFormat],[AudioStreamBasicDescriptions formatASBD:outFormat]);
    
    
    if(inFormat.mFormatFlags && kAudioFormatFlagIsSignedInteger &&
       outFormat.mFormatFlags && kAudioFormatFlagIsSignedInteger)
    {
        return NULL;
    }
    
    
    AudioConverterRef converter = NULL;
    OSStatus err;
    err = AudioConverterNew(&inFormat, &outFormat, &converter);
    CHECK_ERROR(err, "AudioConverterNew fail");
    return converter;
}

-(BOOL)convert:(char *)inBuffer bufferSize:(int) bufferSize
{
    _bufferSize = 0;
    _buffer = NULL;
    
    if((_inFormat.mFormatFlags & kAudioFormatFlagIsSignedInteger)  &&
       (_outFormat.mFormatFlags & kAudioFormatFlagIsSignedInteger)) //int > int
    {
        if (_inFormat.mBytesPerFrame == _outFormat.mBytesPerFrame)
        {
            memcpy(_outputBuffer, inBuffer, bufferSize);
            _buffer = _outputBuffer;
            _bufferSize = bufferSize;

        }else if(_inFormat.mBytesPerFrame == 4 &&
                 _outFormat.mBytesPerFrame == 2 )
        {
            
            //conver 8.24 to int16
            int frame = bufferSize/_inFormat.mBytesPerFrame;
            fixedPointToSInt16((SInt32 *) inBuffer, (SInt16 *)_outputBuffer, frame );
            _buffer = _outputBuffer;
            _bufferSize = frame * _outFormat.mBytesPerFrame;

        }else if(_inFormat.mBytesPerFrame == 2 &&
                 _outFormat.mBytesPerFrame == 4 )
        {
            //cover int16 to 8.24
            int frame = bufferSize/_inFormat.mBytesPerFrame;
            SInt16ToFixedPoint((SInt16 *) inBuffer, (SInt32 *)_outputBuffer, frame );
            _buffer = _outputBuffer;
            _bufferSize = frame * _outFormat.mBytesPerFrame;
            
        }else{
            return NO;
        }
        return YES;
    }else if((_inFormat.mFormatFlags & kAudioFormatFlagIsFloat)  &&
       (_outFormat.mBytesPerFrame == 2))//float->int16
    {
        int frame = bufferSize/_inFormat.mBytesPerFrame;
        floatToSInt16((float*) inBuffer, (SInt16 *)_outputBuffer,frame);
        _buffer = _outputBuffer;
        _bufferSize = frame * _outFormat.mBytesPerFrame;
        return YES;
    }
    
    if (_converter == NULL) {
        return NO;
    }
    
    UInt32 inSize = bufferSize;
    UInt32 outSize = BUFFER_SIZES;
    if (inSize > BUFFER_SIZES) {
        NSLog(@"AudioFormatConverter not enough buffer!");
        return NO;
    }
    
    OSStatus err = AudioConverterConvertBuffer(_converter, inSize, inBuffer, &outSize, _outputBuffer);
    CHECK_ERROR(err, "AudioConverterConvertBuffer fail");
    if(err == noErr){
        _bufferSize = outSize;
        _buffer = _outputBuffer;
        return YES;
    }
    
    return NO;
}


@end

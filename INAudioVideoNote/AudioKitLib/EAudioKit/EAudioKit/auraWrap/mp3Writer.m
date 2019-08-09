//
//  mp3Writer.m
//  EAudioKit
//
//  Created by cybercall on 15/7/29.
//  Copyright © 2015年 rcsing. All rights reserved.
//
#import "platform.h"
#import "mp3Writer.h"
#import "AudioFormatConverter.h"
#import "mp3.h"
#import "EAMicro.h"
#import "EAudioMisc.h"
#import "auraConfig.h"

#define BUFFER_SIZE     (1024 * 1024 * sizeof(float))


@interface mp3Writer()
{
    mp3::Encoder*               _mp3Encoder;
    NSString*                   _path;
    AudioStreamBasicDescription _audioFormat;
    NSFileHandle*               _outputFileHandle;
    AudioFormatConverter*       _leftConverter;
    AudioFormatConverter*       _rightConverter;
    char*                       _buffersOutput;
    char*                       _buffersJoin;
    unsigned long long     _totalFrame;
}
@end


@implementation mp3Writer

-(BOOL)config:(NSString*)path audioSourceFormat:(AudioStreamBasicDescription)format
{


    if (format.mChannelsPerFrame != 2)
        return NO;
    
    if (!(format.mFormatFlags & kAudioFormatFlagIsNonInterleaved))
        return NO;
    
    
    _path = path;
    _audioFormat = format;
    {
        NSFileManager* fileMgr = [NSFileManager defaultManager];
        if ([fileMgr fileExistsAtPath: path ] == NO)
        {
            [fileMgr createFileAtPath: path
                                       contents: nil
                                     attributes: nil];
        }
        
        _outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        if (_outputFileHandle != nil) {
            
           // EncoderType::SHINE_ENCODER
            int encoderType = [auraConfig defaultConfig].mp3EncodeType;
            _mp3Encoder = mp3::CreateEncoder(encoderType);
            
            _mp3Encoder->SetInputSamplerate(format.mSampleRate);
            _mp3Encoder->SetOutputSamplerate(format.mSampleRate);
            _mp3Encoder->SetChannels(format.mChannelsPerFrame);
            
            int qulity = [auraConfig defaultConfig].mp3Quality;
            int bitrate = [auraConfig defaultConfig].mp3Bitrate;
            _mp3Encoder->SetQuality( qulity );
            _mp3Encoder->SetBitrate(bitrate);
            
            AudioStreamBasicDescription outformat = format;
            
           // UInt32 bytesPerSample = sizeof(SInt32);
             UInt32 bytesPerSample = sizeof(SInt16);
            outformat.mFormatFlags =  kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
            
            outformat.mBytesPerPacket    = bytesPerSample;
            outformat.mBytesPerFrame     = bytesPerSample;
            outformat.mBitsPerChannel    = 8 * bytesPerSample;
            
            _leftConverter = [[AudioFormatConverter alloc]init:format outputFormat:outformat];
            _rightConverter = [[AudioFormatConverter alloc]init:format outputFormat:outformat];
            
            _buffersOutput = (char*)malloc(BUFFER_SIZE);
            _buffersJoin = (char*)malloc(BUFFER_SIZE);
            return YES;
        }
        [fileMgr removeItemAtPath:path error:NULL];
    }
    
    return NO;
}

-(void)seekToFileOffset:(unsigned long long)offset{
    [_outputFileHandle seekToFileOffset:offset];
}

- (NSData *)readDataOfLength:(NSUInteger)length{
    
   return  [_outputFileHandle readDataOfLength:length];
}



-(void)dealloc
{
    [self close];
}

-(void)seekEndFile{
    
    unsigned long long totalFrame = [_outputFileHandle seekToEndOfFile];
    [_outputFileHandle truncateFileAtOffset:totalFrame];
    _totalFrame = totalFrame;
}

-(void)resetFile{
     [_outputFileHandle truncateFileAtOffset:_totalFrame];
     [self close];
}

-(OSStatus)pushAudioBuffer:(UInt32)inNumberFrames AudioBufferList:(AudioBufferList*)ioData
{

    if(_mp3Encoder)
    {
        TIME_SLAPS_TRACER("mp3Writer,pushAudioBuffer",0.1);
        if (ioData->mNumberBuffers != 2)
            return kExtAudioFileError_InvalidDataFormat;
        
        if (ioData->mBuffers[0].mDataByteSize * 2 * _audioFormat.mBytesPerFrame > BUFFER_SIZE) {
            NSLog(@"err!!!!!!mp3Writer,not enought memory!!!!");
            return kExtAudioFileError_AsyncWriteBufferOverflow;
        }
        
        int nLeft = ioData->mBuffers[0].mDataByteSize;
        int nRight = ioData->mBuffers[1].mDataByteSize;
        char* left = (char*)ioData->mBuffers[0].mData;
        char* right = (char*)ioData->mBuffers[1].mData;
        BOOL b1 = [_leftConverter convert:left bufferSize:nLeft];
        BOOL b2 = [_rightConverter convert:right bufferSize:nRight];
        if (b1 && b2)
        {
            Int16* inLeft = (Int16*)_leftConverter.buffer;
            Int16* inRight = (Int16*)_rightConverter.buffer;

#if 1
            Int32* buffersJoin = (Int32*)_buffersJoin;
            for (int i = 0; i < _leftConverter.bufferSize; i++) {
                *buffersJoin = ((Int32)inLeft[0] << 16) | ((Int32)(inRight[0] & 0xFFFF));
                inLeft++;
                inRight++;
                buffersJoin ++;
            }
            TIME_SLAPS_TRACER("mp3Writer,pushAudioBuffer,EncodeInterleaved",0.1);
            Int32 nWrite = _mp3Encoder->EncodeInterleaved((Int16*)_buffersJoin, inNumberFrames, (UInt8*)_buffersOutput, BUFFER_SIZE);
#else
            Int32 nWrite = _mp3Encoder->Encode((Int16*)inLeft, (Int16*)inRight, inNumberFrames, (UInt8*)_buffersOutput, BUFFER_SIZE );
#endif

            if(nWrite > 0){
                NSData* data = [NSData dataWithBytesNoCopy:_buffersOutput length:nWrite freeWhenDone:NO];
                [_outputFileHandle writeData:data];
            }
            return noErr;
        }
    }
    return kExtAudioFileError_InvalidDataFormat;
}

-(void)close
{
    if(_mp3Encoder)
    {
        Int32 nWrite = _mp3Encoder->Flush((UInt8*)_buffersOutput, BUFFER_SIZE);
        if (nWrite > 0) {
            NSData* data = [NSData dataWithBytesNoCopy:_buffersOutput length:nWrite freeWhenDone:NO];
            [_outputFileHandle writeData:data];
        }
        _mp3Encoder->Close();
        _mp3Encoder = NULL;
    }
    
    if (_outputFileHandle != nil) {
        [_outputFileHandle closeFile];
        _outputFileHandle = nil;
    }
    
    if (_buffersJoin) {
        free(_buffersJoin);
        _buffersJoin = NULL;
    }
    if (_buffersOutput) {
        free(_buffersOutput);
        _buffersOutput = NULL;
    }
    _leftConverter = nil;
    _rightConverter = nil;
    
}


@end

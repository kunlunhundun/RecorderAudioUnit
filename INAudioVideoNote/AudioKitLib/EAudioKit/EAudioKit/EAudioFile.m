
//
//  AEAudioFileNode.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioFile.h"
#import "EAMicro.h"
#import "EAudioMisc.h"
#import "AEUtilities.h"
#import "EAudioPcmFile.h"

static const int kIncrementalLoadBufferSize = 4096;
static const int kMaxAudioFileReadSize = 16384;

#define INVALID_POS (-1)

@interface EAudioFile()
{
    ExtAudioFileRef             _audioFileRef;
    UInt64                      _fileTotalFrames;
    AudioBufferList*            _audioBufferList;
    SInt64                       _playOffset;
    float                       _delaySeconds;
    EAudioPcmFile*               _audioPcmFile;
    BOOL                        _isEof;

}
@end

@implementation EAudioFile
-(instancetype)init
{
    self = [super init];

    MARK_INSTANCE();
    return self;
}
-(void)dealloc
{
    UNMARK_INSTANCE();
    
    [self close];
    
    CHECK_ERROR(-1,"EAudioFile dealloc\n");
    
}

-(BOOL)openAudioFile:(NSString*)path withAudioDescription:(AudioStreamBasicDescription)clientFormat
{
    [self close];

    NSString* ext = [path pathExtension];
    if ([ext isEqual:@"pcm"])
    {
        _audioPcmFile = [[EAudioPcmFile alloc] initWithPathForRead:path AudioStreamFormat:clientFormat];
        _playOffset = 0;

        _audioFile = path;
        _fileTotalFrames = _audioPcmFile.frameCount;
        _audioFileFormat = _audioPcmFile.audioFormat;
        _clientFormat = clientFormat;
        _audioFrameCount = ceil(_fileTotalFrames * (_clientFormat.mSampleRate / _audioFileFormat.mSampleRate));
        assert(_fileTotalFrames == _audioFrameCount);
        return YES;
    }else{
        return [self openAudioFileNormal:path withAudioDescription:clientFormat];
    }
}

-(BOOL)openAudioFileNormal:(NSString*)path withAudioDescription:(AudioStreamBasicDescription)clientFormat
{
    [self close];
    

    ExtAudioFileRef audioFileRef;
    AudioFileID audioFileID;
    
    NSURL* url = [NSURL fileURLWithPath:path];
    OSStatus err = ExtAudioFileOpenURL((__bridge CFURLRef)url, &audioFileRef);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileOpenURL failed");
    _audioFileRef = audioFileRef;
    _clientFormat = clientFormat;
    
    UInt32 propSize = sizeof(audioFileID);
    err = ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_AudioFile, &propSize, &audioFileID);
    CHECK_ERROR(err,"ExtAudioFileGetProperty kExtAudioFileProperty_AudioFile failed");
    
    AudioStreamBasicDescription audioFileFormat;
    propSize = sizeof(audioFileFormat);
    err = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propSize, &audioFileFormat);
    CHECK_ERROR_MSG_RET_NO(err,"AudioFileGetProperty kAudioFilePropertyDataFormat failed");
    _audioFileFormat = audioFileFormat;
    
    // Apply client format
    err = ExtAudioFileSetProperty(audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(clientFormat), &clientFormat);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed");
    
    [AudioStreamBasicDescriptions printAsbdDif:@"EAudioFile" asbdTitle1:@"audioFile format" format1:audioFileFormat asbdTitle2:@"client format" format2:clientFormat];
    
    if ( clientFormat.mChannelsPerFrame > audioFileFormat.mChannelsPerFrame ) {
        // More channels in target format than file format - set up a map to duplicate channel
        SInt32 channelMap[8];
        AudioConverterRef converter;
        UInt32 propSize = sizeof(converter);
        ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_AudioConverter, &propSize, &converter);
        for ( int outChannel=0, inChannel=0; outChannel < clientFormat.mChannelsPerFrame; outChannel++ ) {
            channelMap[outChannel] = inChannel;
            if ( inChannel+1 < audioFileFormat.mChannelsPerFrame ) inChannel++;
        }
        AudioConverterSetProperty(converter, kAudioConverterChannelMap, sizeof(SInt32)*clientFormat.mChannelsPerFrame, channelMap);
        CFArrayRef config = NULL;
        ExtAudioFileSetProperty(audioFileRef, kExtAudioFileProperty_ConverterConfig, sizeof(CFArrayRef), &config);
    }
    
    
    UInt64 packetCount;
    propSize = sizeof(packetCount);
    err = AudioFileGetProperty(audioFileID, kAudioFilePropertyAudioDataPacketCount, &propSize, &packetCount);
    CHECK_ERROR(err,"AudioFileGetProperty kAudioFilePropertyAudioDataPacketCount failed");
    
    if (err == noErr) {
        _isEof = NO;
        _playOffset = 0;
        _audioFile = path;
        _audioFileId = audioFileID;
        _audioFileFormat = audioFileFormat;
        _fileTotalFrames = packetCount * audioFileFormat.mFramesPerPacket;
        _audioFrameCount = ceil(_fileTotalFrames * (_clientFormat.mSampleRate / _audioFileFormat.mSampleRate));
        
        return YES;
    }
    return NO;
}


-(void)close
{
    if (_audioBufferList) {
        AEFreeAudioBufferList(_audioBufferList);
        _audioBufferList = NULL;
    }
    if (_audioFileRef) {
        ExtAudioFileDispose(_audioFileRef);
        _audioFileRef = NULL;
        _audioFileId = NULL;
        _audioFile = @"";
        NSLog(@"audio file closed");
    }
    _audioPcmFile = nil;
    _isEof = YES;
}

-(int) feedBufferList:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount
{
    SInt64 playOffset = _playOffset;
    if (playOffset < 0)//延時播放
    {
        [EAudioMisc fillSilence:bufferList];
        playOffset += frameCount;
        if (playOffset <= 0)
        {
            _playOffset = playOffset;
            return frameCount;
        }else
        {
            _playOffset = 0;
            int offset = frameCount - playOffset;
            int frame = playOffset;
            char temp[sizeof(AudioBufferList)+sizeof(AudioBuffer)];
            AudioBufferList* wrap = monitorBufferList(temp, bufferList, offset, _audioFileFormat.mBytesPerFrame);
            int read = [self feedBufferList:wrap frameCount:frame];
            return (read + offset);
        }
    }
    
    if (_audioPcmFile != nil) {
        int n = [_audioPcmFile audioFileRead:bufferList inNumberFrames:frameCount];
        _playOffset += n;
        return n;
    }
    
    if (_audioBufferList) {
        int read = [self readAudioBufferListEx:bufferList
                              BufferFrameCount:frameCount
                                  fromFramePos:_playOffset];
        _playOffset += read;
        return read;
    }
    
    if( _playOffset >= _audioFrameCount )
        return 0;
        

    UInt32 frameRead = [self audioFileRead:bufferList frameCount:frameCount];
     _playOffset += frameRead;
    
    if (frameRead < frameCount) {
        //maybe file end,
        if (_playOffset < _audioFrameCount) {
            NSLog(@"warning!!!maybe audio file bad...");
            _playOffset = _audioFrameCount + 1;//let it end
        }
    }

    return frameRead;

}

-(int)audioFileRead:(AudioBufferList*)bufferList frameCount:(UInt32)frameCount
{
    //notice: ExtAudioFileRead will change bufferList->mBuffers].mDataByteSize
    UInt32 frameRead = 0;
    char temp[sizeof(AudioBufferList)+sizeof(AudioBuffer)];
    AudioBufferList* wrap = monitorBufferList(temp, bufferList, 0, _audioFileFormat.mBytesPerFrame);

    while (frameRead < frameCount && !_isEof)
    {
        UInt32 frame = (frameCount - frameRead);
        OSStatus status = ExtAudioFileRead(_audioFileRef, &frame, wrap);
        CHECK_ERROR(status, "ExtAudioFileRead fail");
        if (status == noErr)
        {
            if (frame == 0 ) {
                _isEof = YES;
            }
            frameRead += frame;
            if (_playOffset + frameRead >= _audioFrameCount) {
                _isEof = YES;
                break;
            }
            wrap = monitorBufferList(temp, bufferList, frameRead, _audioFileFormat.mBytesPerFrame);
            if (frameRead != frameCount )
            {
              //liurg  NSLog(@"ExtAudioFileRead error ??? i don't know....");
            }
        }else
        {
            _isEof = YES;
            break;
        }
    }
    
    return frameRead;
}


-(BOOL)seekToFrame:(float)second
{
    //MUST BE RUN IN AudioThread
    
    _playOffset = _clientFormat.mSampleRate * (second - _delaySeconds);
    
    NSLog(@"second:%.3f -->>>>_delaySeconds:%.3f \n",second,_delaySeconds);
    
    int fileOffset = _audioFileFormat.mSampleRate * (second - _delaySeconds);
    
    _isEof = (_fileTotalFrames <= fileOffset);
    if (!_isEof)
    {
        if (_audioFileRef) {
            
            OSStatus status = ExtAudioFileSeek(_audioFileRef,fileOffset);
            CHECK_ERROR(status, "ExtAudioFileSeek fail");
            
        }else if(_audioPcmFile != nil){
            [_audioPcmFile seek:fileOffset];
        }
    }

    return YES;
}

-(void)setDelay:(float)second
{
    _delaySeconds = second;
}

//read total audio file to bufferlist
//call readAudioBufferListEx to read the buffer
-(BOOL)openAudioFileEx:(NSString*)path withAudioDescription:(AudioStreamBasicDescription)clientFormat
{
    BOOL open = [self openAudioFile:path withAudioDescription:clientFormat];
    if (open) {
        return [self readAllToBufferList];
    }
    return NO;
}

-(BOOL) readAllToBufferList
{
    if (_audioFrameCount <= 0) {
        return NO;
    }
    TIME_SLAPS_TRACER("EAudioFile_readAllToBufferList",0.1);
    
    UInt64 fileLengthInFrames = _audioFrameCount;
    // Prepare buffers
    int bufferCount = (_clientFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? _clientFormat.mChannelsPerFrame : 1;
    int channelsPerBuffer = (_clientFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? 1 : _clientFormat.mChannelsPerFrame;
    AudioBufferList *bufferList = AEAllocateAndInitAudioBufferList(_clientFormat, fileLengthInFrames);
    if ( !bufferList ) {
        NSLog(@"AEAllocateAndInitAudioBufferList fail");
        return NULL;
    }
    
    AudioBufferList *scratchBufferList = AEAllocateAndInitAudioBufferList(_clientFormat, 0);
    OSStatus status;
    // Perform read in multiple small chunks (otherwise ExtAudioFileRead crashes when performing sample rate conversion)
    UInt64 readFrames = 0;
    while ( readFrames < fileLengthInFrames) {
        {
            for ( int i=0; i<scratchBufferList->mNumberBuffers; i++ ) {
                scratchBufferList->mBuffers[i].mNumberChannels = channelsPerBuffer;
                scratchBufferList->mBuffers[i].mData = (char*)bufferList->mBuffers[i].mData + readFrames*_clientFormat.mBytesPerFrame;
                scratchBufferList->mBuffers[i].mDataByteSize = (UInt32)MIN(kMaxAudioFileReadSize, (fileLengthInFrames-readFrames) * _clientFormat.mBytesPerFrame);
            }
        }
        
        // Perform read
        UInt32 numberOfPackets = (UInt32)(scratchBufferList->mBuffers[0].mDataByteSize / _clientFormat.mBytesPerFrame);
        status = ExtAudioFileRead(_audioFileRef, &numberOfPackets, scratchBufferList);
        
        if ( status != noErr ) {
            free(scratchBufferList);
            return NO;
        }
        
        if ( numberOfPackets == 0 ) {
            // Termination condition
            break;
        }
        readFrames += numberOfPackets;
    }
    _audioBufferList = bufferList;
    free(scratchBufferList);
    return YES;
}

//从内存直接读取AudioBufferList
-(UInt64)readAudioBufferListEx:(AudioBufferList*)bufferList
              BufferFrameCount:(UInt64)frameCount
                  fromFramePos:(UInt64)frameOffset
{
    if (!_audioBufferList) {
        NSLog(@"no found audio buffer,call openAudioFileToBuffer first");
        return 0;
    }
    
    SInt64 frame;
    SInt64 left = 0;
    if (frameOffset + frameCount > _audioFrameCount) {
        frame = (_audioFrameCount - frameOffset);
        left = frameOffset + frameCount - _audioFrameCount;
    }else{
        frame = frameCount ;
    }
    if (frame <= 0 ) {
        return frame;
    }

    UInt64 len = frame * _clientFormat.mBytesPerFrame;
    UInt64 offset = frameOffset * _clientFormat.mBytesPerFrame;
    for(int i=0; i <_audioBufferList->mNumberBuffers; i++)
    {
        memcpy(bufferList->mBuffers[i].mData,
               ((char*)_audioBufferList->mBuffers[i].mData)+offset,
               len);
        bufferList->mBuffers[i].mDataByteSize = len;
    }
    
    return frame;
}
@end

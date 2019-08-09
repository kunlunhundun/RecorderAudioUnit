//
//  FileAsynWriter.m
//  EAudioKit
//
//  Created by cybercall on 15/8/26.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "EAudioPcmFile.h"

#import "EAudioMisc.h"
#import "EAudioNodeRecorder.h"

#define HEADER_LENGTH   (sizeof(AudioStreamBasicDescription))
#define INVALID_POS     (-1)

@interface EAudioPcmFile ()
{
    NSOperationQueue*            _operationQueue;
    NSFileHandle*                _fileHandle;
    AudioStreamBasicDescription  _clientFormat;
    BOOL                         _openForRead;
    UInt64                       _fileEndPos;
    void*                        _tempBuffer;
    int                          _tempBufferSize;
}

@end



@implementation EAudioPcmFile

-(instancetype)initWithPathForWrite:(NSString*)path AudioStreamFormat:(AudioStreamBasicDescription)audioStreamFormat
{
    self = [super init ];
    
    _path = path;
    _audioFormat = audioStreamFormat;
    _openForRead = NO;

    [self resetFileHandle];

    return self;
}
- (void)resetFileHandle{
    [self close];
    if (_audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _operationQueue.name = @"EAudioPcmFile queue";
        [[NSFileManager defaultManager] createFileAtPath:_path contents:nil attributes:nil];
        _tempBufferSize = 2 * _audioFormat.mSampleRate * _audioFormat.mBytesPerFrame * _audioFormat.mChannelsPerFrame;
        _tempBuffer = malloc(_tempBufferSize);
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_path];
        if (_fileHandle != nil) {
            [self writePCMHeader];;
        }
        
    }else{
        NSLog(@"warning AudioPcmFile not support!!!");
    }
}

-(instancetype)initWithPathForRead:(NSString*)path AudioStreamFormat:(AudioStreamBasicDescription)clientFormat
{
    self = [super init ];
    
    _path = path;
    _clientFormat = clientFormat;
    _openForRead = YES;
    _fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    _fileEndPos = 0;
    if (_fileHandle != nil)
    {
        [self readPCMHeader];
        if (clientFormat.mFormatFlags == 0 ) {
            clientFormat = _audioFormat;
            clientFormat.mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
            _clientFormat = clientFormat;
        }
        AudioFormatFlags flags = _audioFormat.mFormatFlags & _clientFormat.mFormatFlags;
        if (!(_audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) &&
            _audioFormat.mBytesPerFrame == _clientFormat.mBytesPerFrame)
        {
            if ( flags & kAudioFormatFlagIsSignedInteger ||
                flags & kAudioFormatFlagIsFloat) {
                
                assert(_audioFormat.mBytesPerFrame == clientFormat.mBytesPerFrame);
                assert(_audioFormat.mSampleRate == clientFormat.mSampleRate);
                assert(_audioFormat.mFormatID == clientFormat.mFormatID);
                
                UInt64 offset = [_fileHandle offsetInFile];
                UInt64 endOffset = [_fileHandle seekToEndOfFile];
                UInt64 dataLen = endOffset - offset;
                UInt64 frameCount = dataLen / _audioFormat.mBytesPerFrame/_audioFormat.mChannelsPerFrame;
                _fileEndPos = endOffset;
                _frameCount = frameCount;
                [_fileHandle seekToFileOffset:offset];
                
                NSLog(@"EAudioPcmFile,open for read,frameCount:%llu",_frameCount);
            }
        }
    }
    
    return self;
}


-(void)dealloc
{
    NSLog(@"EAudioPcmFile dealloc\n");
    [self close];
}

-(void)readPCMHeader
{
    NSData* data = [_fileHandle readDataOfLength:HEADER_LENGTH];
    if (data != nil) {
        memcpy(&_audioFormat, data.bytes, sizeof(_audioFormat));
    }
    
}

-(void)writePCMHeader
{
    AudioStreamBasicDescription audioFormat = _audioFormat;
    audioFormat.mFormatFlags = audioFormat.mFormatFlags & ~kAudioFormatFlagIsNonInterleaved;
    NSData* data = [NSData dataWithBytes:&audioFormat length:HEADER_LENGTH];
    [_fileHandle writeData:data];

}

-(int)audioFileRead:(AudioBufferList*)ioData inNumberFrames:(UInt32)inNumberFrames
{
    if (!_openForRead) {
        return 0;
    }

     int frameRead = 0;
    
    // test_bug_auto
    @autoreleasepool {
        int size = inNumberFrames * _audioFormat.mBytesPerFrame * _audioFormat.mChannelsPerFrame;
        NSData* data = [_fileHandle readDataOfLength:size];
      //  char* samples = (char*)data.bytes;
        if (data != nil)
        {
            frameRead = data.length / _audioFormat.mBytesPerFrame/_audioFormat.mChannelsPerFrame;
            
            if(_clientFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved)
            {
                char* ptr[2] = {(char*)ioData->mBuffers[0].mData,NULL};
                if (ioData->mNumberBuffers>1) {
                    ptr[1] = (char*)ioData->mBuffers[1].mData;
                }
                int sampleSize = _audioFormat.mBytesPerFrame;
                for(int i=0; i<2; i++)
                {
                    char* p = ptr[i];
                    if (p)
                    {
                        char* src = (char*)data.bytes + i*sampleSize;
                        for(int j=0; j<frameRead; j++)
                        {
                            memcpy(p, src, sampleSize);
                            p += sampleSize;
                            src += sampleSize * 2;
                        }
                    }
                }
            }else{
                NSLog(@"EAudioPcmFile audioFileRead error,not support this audioFormat");
            }
            _offset += frameRead;
            //NSLog(@"EAudioPcmFile,audioFileRead,read:%d,offset:%llu",inNumberFrames,_offset);
        }
    }
    
    return frameRead;
}


-(void)audioFileWrite:(AudioBufferList*)ioData inNumberFrames:(UInt32)inNumberFrames
{
    if (_fileHandle == nil || _operationQueue == nil) {
        return;
    }
    
    assert(inNumberFrames * _audioFormat.mBytesPerFrame <= ioData->mBuffers[0].mDataByteSize);
    // test_bug_auto
    @autoreleasepool {
        NSData* right = nil;
        NSData*  left = [NSData dataWithBytes:ioData->mBuffers[0].mData
                                       length:inNumberFrames * _audioFormat.mBytesPerFrame];
        if (ioData->mNumberBuffers > 1)
        {
            right = [NSData dataWithBytes:ioData->mBuffers[1].mData
                                   length:inNumberFrames * _audioFormat.mBytesPerFrame];

        }else{
            char* mapLeft = (char*)left.bytes;
            right = [NSData dataWithBytesNoCopy:mapLeft length:left.length freeWhenDone:NO];
        }
        
        NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
            [self writeData:left Right:right inNumberFrames:inNumberFrames];
        }];
        [_operationQueue addOperation:operation];
    }
    
    _frameCount += inNumberFrames;
}


-(void)writeData:(NSData*)left Right:(NSData*)right inNumberFrames:(int)inNumberFrames
{
    int sampleSize = _audioFormat.mBytesPerFrame;
    
    if (_audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved)
    {
        int frameMax = _tempBufferSize/sampleSize/2;
        
        char* l = (char*)left.bytes;
        char* r = (char*)right.bytes;
        
        while (inNumberFrames > 0)
        {
            char* p = (char*)_tempBuffer;
            int frame = MIN(inNumberFrames, frameMax);
            for(int i=0; i < frame; i++)
            {
                memcpy(p,l , sampleSize);
                p += sampleSize;
                l += sampleSize;
                memcpy(p,r , sampleSize);
                p += sampleSize;
                r += sampleSize;
            }
            inNumberFrames -= frame;
            
            int size = (frame*sampleSize*2);
            NSData* data = [NSData dataWithBytesNoCopy:_tempBuffer length:size freeWhenDone:NO];
            [_fileHandle writeData:data];
        }
        
    }else
    {
        NSLog(@"EAudioPcmFile writeData error,not support this audioFormat");
    }
}

-(void)seek:(SInt64)frame
{
    if (_fileHandle == nil ) {
        return;
    }
    if (_openForRead)
    {
        if (frame > _frameCount) {
            frame = _frameCount;
        }
        UInt64 pos = _audioFormat.mBytesPerFrame * frame * _audioFormat.mChannelsPerFrame + HEADER_LENGTH;
        if (pos >= _fileEndPos) {
            NSLog(@"ERROR,EAudioPcmFile,seek fail,out of file length");
            return ;
        }
        [_fileHandle seekToFileOffset:pos];

    }else
    {
        NSBlockOperation* operation;
        if (frame <= _frameCount) {
            if (frame < 0 ){
                frame = 0;
            }
            operation = [NSBlockOperation blockOperationWithBlock:^{
                UInt64 pos = _audioFormat.mChannelsPerFrame * _audioFormat.mBytesPerFrame * frame + HEADER_LENGTH;
                [_fileHandle seekToFileOffset:pos];
                [_fileHandle truncateFileAtOffset:pos];
                _frameCount = frame;
                
            }];
        }else{
            UInt64 blankFrameCount = frame - _frameCount;
            UInt64 size = blankFrameCount * _audioFormat.mBytesPerFrame * _audioFormat.mChannelsPerFrame;
            operation = [NSBlockOperation blockOperationWithBlock:^{
                void* zero = malloc( size);
                memset(zero, 0, size);
                NSData* data = [NSData dataWithBytesNoCopy:zero length:size];
                [_fileHandle writeData:data];
                _frameCount = _frameCount + blankFrameCount;
                
            }];
        }

        [_operationQueue addOperation:operation];
    }
}

-(void)flush
{
    if (_openForRead) {
        return;
    }
    [_operationQueue waitUntilAllOperationsAreFinished];
}
-(void)close
{
    if (_operationQueue != nil) {
        [self flush];
        _operationQueue = nil;
    }
    
    if (_fileHandle != nil) {
        [_fileHandle closeFile];
        _fileHandle = nil;
    }
    if (_tempBuffer) {
        free(_tempBuffer);
        _tempBuffer = NULL;
    }
    NSLog(@"EAudioPcmFile close.");
}
- (void)clear{
    
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        if (_fileHandle != nil) {
            [_fileHandle closeFile];
            _fileHandle = nil;
        }
       [[NSFileManager defaultManager] createFileAtPath:_path contents:nil attributes:nil];
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_path];
        if (_fileHandle != nil) {
            [self writePCMHeader];
        }
    }];
    [_operationQueue addOperation:operation];
    
//    [self resetFileHandle];
}
- (void)addOPerationQueue:(NSBlockOperation *)operation{
    [_operationQueue addOperation:operation];
}

+(void)pcmToAudioFile:(NSString*)pcmFile targetAudioFile:(NSString*)audioFile
{
    AudioStreamBasicDescription format;
    memset(&format, 0, sizeof(format));
    
    EAudioPcmFile* pcm = [[EAudioPcmFile alloc] initWithPathForRead:pcmFile AudioStreamFormat:format];
    format = pcm.audioFormat;
    format.mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
    
    EAudioRenderBufferRecorder* recorder = [[EAudioRenderBufferRecorder alloc] init];
    [recorder setup:audioFile AudioStreamFormat:format enableSynWrite:YES];
    
    int frameCount = 1024;
    AudioBufferList* audioBufferList = allocAudioBufferList(format,frameCount);
    
    while (true) {
        int read = [pcm audioFileRead:audioBufferList inNumberFrames:frameCount];
        [recorder pushAudioBuffer:0 AudioTimeStamp:0 inBusNumber:0 inNumberFrames:read AudioBufferList:audioBufferList];
        if (read != frameCount) {
            break;
        }
    }
    
    [pcm close];
    [recorder close];
    
}

@end

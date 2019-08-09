//
//  AEAudioFileNode.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioNodeRecorder.h"
#import "EAInteranl.h"
#import "EAudioMisc.h"
#import "EAMicro.h"
#import "mp3Writer.h"
#import "EAudioConfig.h"

#pragma mark ---- EAudioRenderBufferRecorder ----
@interface EAudioRenderBufferRecorder()
{
     ExtAudioFileRef _extAudioFile;
    BOOL             _synWrite;
    NSString*        _filePath;
    
    AudioStreamBasicDescription _clientFormat;
    AudioStreamBasicDescription _destFormat;
    UInt32                     _priorMixOverrideValue;

    mp3Writer*       _mp3Writer;

}
@end

@implementation EAudioRenderBufferRecorder

-(instancetype)init
{
    self = [super init];

    _synWrite = NO;
    return self;
}

-(void)dealloc
{
    [self close];
    
}


-(BOOL)setup:(NSString*)file AudioStreamFormat:(AudioStreamBasicDescription)audioStreamFormat enableSynWrite:(BOOL)enableSynWrite
{
    _synWrite = enableSynWrite;
    _filePath = file;
    _clientFormat = audioStreamFormat;
    NSString* ext = [file pathExtension];
    AudioFileTypeID fileTypeId = [EAudioMisc AudioFileTypeForExtension: ext ];
    AudioFormatID formatId = [EAudioMisc AudioFormatIDForExtension: ext ];

    
    if ( fileTypeId == kAudioFileM4AType )
    {
        return [self setupAACWriter];
        
    }else if ( fileTypeId == kAudioFileMP3Type ){

        _mp3Writer = [[mp3Writer alloc] init];
        if ([_mp3Writer config:file audioSourceFormat:audioStreamFormat]) {
            return YES;
        }
        _mp3Writer = nil;

        return NO;
    }
    
    OSStatus err;
    AudioStreamBasicDescription destinationFormat;
    if (0) {
        memset(&destinationFormat, 0, sizeof(destinationFormat));
        destinationFormat.mChannelsPerFrame = audioStreamFormat.mChannelsPerFrame;//2;
        destinationFormat.mFormatID = formatId;
        destinationFormat.mSampleRate = audioStreamFormat.mSampleRate;//16000.0;
        // destinationFormat.mFormatFlags = audioStreamFormat.mFormatFlags;
        
        UInt32 size = sizeof(destinationFormat);
        err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
        CHECK_ERROR_MSG_RET_NO(err,"kAudioFormatProperty_FormatInfo failed");

    }else{
        FillOutASBDForLPCM(destinationFormat,audioStreamFormat.mSampleRate,audioStreamFormat.mChannelsPerFrame,32,32,true,false,false);
    }
    
     _destFormat = destinationFormat;
    
    [AudioStreamBasicDescriptions printAsbdDif:@"EAudioRenderBufferRecorder" asbdTitle1:@"source format" format1:audioStreamFormat asbdTitle2:@"target format" format2:destinationFormat];
    
    ExtAudioFileRef extAudioFile;
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (CFStringRef)file,
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    err = ExtAudioFileCreateWithURL(destinationURL, fileTypeId, &destinationFormat, NULL, kAudioFileFlags_EraseFile, &extAudioFile);
    CFRelease(destinationURL);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileCreateWithURL failed");
    _extAudioFile = extAudioFile;
    
    // specify codec
    UInt32 codec = kAppleSoftwareAudioCodecManufacturer;//kAppleHardwareAudioCodecManufacturer;
    err = ExtAudioFileSetProperty(extAudioFile,
                                  kExtAudioFileProperty_CodecManufacturer,
                                  sizeof(codec),
                                  &codec);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileSetProperty kExtAudioFileProperty_CodecManufacturer failed");
    
    err = ExtAudioFileSetProperty(extAudioFile,
                                  kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(audioStreamFormat),
                                  &audioStreamFormat);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed");
    
    if (!_synWrite) {
        err = ExtAudioFileWriteAsync(extAudioFile, 0, NULL);
    }
        
    
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileWriteAsync failed");

    return YES;

}

-(BOOL)setupAACWriter
{
    OSType audioCodecManufacturer;
    if ([EAudioMisc AACEncodingAvailable:&audioCodecManufacturer] == NO) {
        NSLog(@"recorde error,not support the file format");
        return NO;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // AAC won't work if the 'mix with others' session property is enabled. Disable it if it's on.
    UInt32 size = sizeof(_priorMixOverrideValue);
    _priorMixOverrideValue = audioSession.categoryOptions & AVAudioSessionCategoryOptionMixWithOthers;
    
    if ( _priorMixOverrideValue != 0 ) {
        NSError *error = nil;
        if ( ![audioSession setCategory:audioSession.category
                            withOptions:audioSession.categoryOptions & ~AVAudioSessionCategoryOptionMixWithOthers
                                  error:&error] ) {
            NSLog(@"Couldn't update category options: %@", error);
            return NO;
        }
    }

    // Get the output audio description
    AudioStreamBasicDescription destinationFormat;
    memset(&destinationFormat, 0, sizeof(destinationFormat));
    destinationFormat.mChannelsPerFrame = 2;
    destinationFormat.mSampleRate = _clientFormat.mSampleRate;//(_clientFormat.mSampleRate >= 44100 ? 64000 : 32000);
#if 1
    destinationFormat.mFormatID          = kAudioFormatMPEG4AAC;
    destinationFormat.mFormatFlags       = kMPEG4Object_AAC_Main;
#else
    destinationFormat.mFormatFlags       = kMPEG4Object_AAC_SBR;
    destinationFormat.mFormatID          = kAudioFormatMPEG4AAC_HE;
#endif
    destinationFormat.mFramesPerPacket    = 1024;
    
    size = sizeof(destinationFormat);
    
    [AudioStreamBasicDescriptions printAsbdDif:@"EAudioRenderBufferRecorder" asbdTitle1:@"source format" format1:_clientFormat asbdTitle2:@"target format" format2:destinationFormat];
    
    OSStatus status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
    CHECK_ERROR_MSG_RET_NO(status,"AudioFormatGetProperty kAudioFormatProperty_FormatInfo failed");

    // Create the file
    ExtAudioFileRef extAudioFile;
    status = ExtAudioFileCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:_filePath],
                                       kAudioFileM4AType,
                                       &destinationFormat,
                                       NULL,
                                       kAudioFileFlags_EraseFile,
                                       &extAudioFile);
    
    CHECK_ERROR_MSG_RET_NO(status,"ExtAudioFileCreateWithURL failed");

    
    UInt32 codecManfacturer = audioCodecManufacturer;//kAppleSoftwareAudioCodecManufacturer
    if( codecManfacturer == kAppleHardwareAudioCodecManufacturer){
        NSLog(@"kAppleHardwareAudioCodecManufacturer YES!");
    }
    
    status = ExtAudioFileSetProperty(extAudioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManfacturer);
    
    if (status != noErr)
    {
        SHOW_ERROR(status,"ExtAudioFileSetProperty kExtAudioFileProperty_CodecManufacturer kAppleSoftwareAudioCodecManufacturer failed!! ");
        ExtAudioFileDispose(extAudioFile);
        return NO;
    }
    
    
    status = ExtAudioFileSetProperty(extAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &_clientFormat);
    if (status != noErr) {
        SHOW_ERROR(status,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed!");
        ExtAudioFileDispose(extAudioFile);
        return NO;
    }
    
    //設置bitrate
    AudioConverterRef audioConverter;
    size = sizeof(audioConverter);
    status = ExtAudioFileGetProperty(extAudioFile, kExtAudioFileProperty_AudioConverter, &size, &audioConverter);
    if (status == noErr) {
        UInt32 bitRate = 0;
        size = sizeof(bitRate);
        status = AudioConverterGetProperty(audioConverter, kAudioConverterEncodeBitRate, &size, &bitRate);
        if( status == noErr ){
            UInt32 newBitRate = [EAudioConfig defaultConfig].aacBitRate;
            if(bitRate != newBitRate){
                status = AudioConverterSetProperty(audioConverter, kAudioConverterEncodeBitRate, size, &newBitRate);
                if( status != noErr ){
                    SHOW_ERROR(status,"AudioConverterSetProperty kAudioConverterEncodeBitRate failed!");
                }
            }
        }
    }else{
        SHOW_ERROR(status,"ExtAudioFileGetProperty kExtAudioFileProperty_AudioConverter failed!");
    }

    _extAudioFile = extAudioFile;
    _destFormat = destinationFormat;
    
    if (!_synWrite) {
        status = ExtAudioFileWriteAsync(extAudioFile, 0, NULL);
    }
    
    return YES;
    
}

-(OSStatus)pushAudioBuffer:(AudioUnitRenderActionFlags*)ioActionFlags
        AudioTimeStamp:(const AudioTimeStamp *)inTimeStamp
           inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames
       AudioBufferList:(AudioBufferList*)ioData
{
    if (_extAudioFile)
    {
        if (_synWrite) {
            return (ExtAudioFileWrite(_extAudioFile, inNumberFrames, ioData));
        }else{
            return (ExtAudioFileWriteAsync(_extAudioFile, inNumberFrames, ioData));
        }
    }else if(_mp3Writer){
       return [_mp3Writer pushAudioBuffer:inNumberFrames AudioBufferList:ioData];
    }

    return noErr;
}

-(void)fillSilence
{
    int second = 1;
    int frame = _clientFormat.mSampleRate * second;
    AudioBufferList* ioData = (AudioBufferList*)malloc(sizeof(AudioBufferList) + (_clientFormat.mChannelsPerFrame - 1) * sizeof(AudioBuffer));
    int inNumberFrames = 1024;
    ioData->mNumberBuffers = _clientFormat.mChannelsPerFrame;
    ioData->mBuffers[0].mDataByteSize = inNumberFrames * _clientFormat.mBytesPerFrame;
    ioData->mBuffers[0].mData = malloc(ioData->mBuffers[0].mDataByteSize);
    memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
    if (_clientFormat.mChannelsPerFrame > 1) {
        ioData->mBuffers[1].mDataByteSize = ioData->mBuffers[0].mDataByteSize;
        ioData->mBuffers[1].mData = ioData->mBuffers[0].mData;
    }
    OSStatus err;
    for (int i=0; i < frame; i += inNumberFrames) {
        if (_synWrite) {
            err = ExtAudioFileWrite(_extAudioFile, inNumberFrames, ioData);
        }else{
            err = ExtAudioFileWriteAsync(_extAudioFile, inNumberFrames, ioData);
        }
    }
    free(ioData->mBuffers[0].mData);
    free(ioData);
}

-(void)close
{
    if( _mp3Writer == nil && _extAudioFile == NULL){
        return;
    }
    
    if (_extAudioFile) {
        
        [self fillSilence];
        
        ExtAudioFileDispose(_extAudioFile);
        _extAudioFile = NULL;
    }
    
    _mp3Writer = nil;
    
    if ( _priorMixOverrideValue ) {
        NSError *error = nil;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ( ![audioSession setCategory:audioSession.category
                            withOptions:audioSession.categoryOptions | AVAudioSessionCategoryOptionMixWithOthers
                                  error:&error] ) {
            NSLog(@"Couldn't update category options: %@", error);
        }
        _priorMixOverrideValue = 0;
    }
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSDictionary<NSString *, id>* dict = [fileMgr attributesOfItemAtPath:_filePath error:NULL];
    if(dict != nil){
        float size = [dict fileSize] / 1024.0;
        NSLog(@"çç,%@,size:%.2fKb",_filePath,size);
    }
    
}


@end

#pragma mark ---- EAudioNodeRecorder ----
@interface EAudioNodeRecorder()
{
    AudioUnit   _audioUnit;
    EAudioRenderBufferRecorder* _bufferRecorder;
    BOOL            _rendering;
}
@end

static OSStatus audioUnitRenderCallback(void* inRefCon,
                                        AudioUnitRenderActionFlags *	ioActionFlags,
                                        const AudioTimeStamp *			inTimeStamp,
                                        UInt32							inBusNumber,
                                        UInt32							inNumberFrames,
                                        AudioBufferList * 	ioData)
{
    
    BOOL isPostRender = (*ioActionFlags & kAudioUnitRenderAction_PostRender);
    if (!isPostRender) { return noErr; }
    
    EAudioRenderBufferRecorder* recorder = (__bridge EAudioRenderBufferRecorder *)(inRefCon);
    
    OSStatus err = [recorder pushAudioBuffer:ioActionFlags AudioTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames AudioBufferList:ioData];
    
    CHECK_ERROR(err,"Record data to file fail");
    
    return err;
}

@implementation EAudioNodeRecorder

-(instancetype)init
{
    self = [super init];
    
    MARK_INSTANCE();
    
    return self;
}

-(void)dealloc
{
    UNMARK_INSTANCE();
    [self detach];
    CHECK_ERROR(-1,"EAudioNodeRecorder dealloc\n");
    
}

-(BOOL)attachAudioNode:(AudioUnit)audioUnit outputPath:(NSString*)file enableSynWrite:(BOOL)enableSynWrite
{
    if (_rendering) {
        NSLog(@"error,recording,plz detach it");
        return NO;
    }
    
    AudioStreamBasicDescription nodeAudioFormat;
    UInt32 fSize = sizeof (nodeAudioFormat);
    memset(&nodeAudioFormat, 0, fSize);
    OSStatus err = AudioUnitGetProperty(audioUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Output,
                               0,
                               &nodeAudioFormat,
                               &fSize);
    CHECK_ERROR_MSG_RET_NO(err,"AudioUnitGetProperty kAudioUnitProperty_StreamFormat failed");

    
     _bufferRecorder = [[EAudioRenderBufferRecorder alloc] init];
    
    BOOL bSetup = [_bufferRecorder setup:file AudioStreamFormat:nodeAudioFormat enableSynWrite:enableSynWrite];
    if (bSetup) {
        err = AudioUnitAddRenderNotify(audioUnit, audioUnitRenderCallback, (__bridge void * __nullable)(_bufferRecorder));
        CHECK_ERROR_MSG_RET_NO(err,"AudioUnitAddRenderNotify failed");
        
        _rendering = YES;
        _audioUnit = audioUnit;
        NSLog(@"recording begin...");
        return YES;
    }

    return NO;
    
}

-(void)detach
{
    if (_rendering) {
        AudioUnitRemoveRenderNotify(_audioUnit, audioUnitRenderCallback, (__bridge void * __nullable)(_bufferRecorder));
        _rendering = NO;
        NSLog(@"recording end...");
    }
    if (_bufferRecorder) {
        [_bufferRecorder close];
        _bufferRecorder = nil;
    }
    
    
}

@end

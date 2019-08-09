//
//  EAudioFileRecorder.m
//  EAudioKit
//
//  Created by kunlun on 30/07/2019.
//  Copyright © 2019 rcsing. All rights reserved.
//

#import "EAudioFileRecorder.h"
#import "EAInteranl.h"
#import "EAudioMisc.h"
#import "EAMicro.h"
#import "mp3Writer.h"
#import "EAudioConfig.h"
#import "AEUtilities.h"


@interface EAudioFileRecorder(){
    
    ExtAudioFileRef _extAudioFile;
    BOOL             _synWrite;
    NSString*        _filePath;
    
    AudioStreamBasicDescription _clientFormat;
    AudioStreamBasicDescription _destFormat;
    
    AudioStreamBasicDescription _audioFileFormat;
    
    UInt32                     _priorMixOverrideValue;
    
    mp3Writer*       _mp3Writer;
    UInt64            _totalFrames;
    BOOL             _isEof;
    BOOL             _isReset;
    NSTimeInterval  _duration;
    float           *_outFloatData;

}

@end

@implementation EAudioFileRecorder



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


-(BOOL)openFile:(NSString*)path AudioStreamFormat:(AudioStreamBasicDescription)audioStreamFormat{

    _clientFormat = audioStreamFormat;
    NSString* ext = [path pathExtension];
    _filePath = path;
    AudioFileTypeID fileTypeId = [EAudioMisc AudioFileTypeForExtension: ext ];

   /*
    ExtAudioFileRef audioFileRef;
    AudioFileID audioFileID;
    NSString* ext = [path pathExtension];
    NSURL* url = [NSURL fileURLWithPath:path];
    OSStatus err = AudioFileOpenURL((__bridge CFURLRef)url, kAudioFileReadWritePermission, 0, &audioFileID);
    CHECK_ERROR_MSG_RET_NO(err,"AudioFileOpenURL failed");
    err = ExtAudioFileWrapAudioFileID(audioFileID, YES, &audioFileRef);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileWrapAudioFileID failed");
    _extAudioFile = audioFileRef;
    UInt32 propSize;
    AudioStreamBasicDescription audioFileFormat;
    propSize = sizeof(audioFileFormat);
    err = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propSize, &audioFileFormat);
    CHECK_ERROR_MSG_RET_NO(err,"AudioFileGetProperty kAudioFilePropertyDataFormat failed");
    _audioFileFormat = audioFileFormat;
    propSize = sizeof(UInt64);
    ExtAudioFileGetProperty(_extAudioFile,
                            kExtAudioFileProperty_FileLengthFrames,
                            &propSize,
                            &_totalFrames);
    _duration = (NSTimeInterval) _totalFrames / audioFileFormat.mSampleRate; */


    if ([ext containsString:@"wav"] ) {
       
        // specify codec
      /*  UInt32 codec = kAppleSoftwareAudioCodecManufacturer;//kAppleHardwareAudioCodecManufacturer;
        err = ExtAudioFileSetProperty(audioFileRef,
                                      kExtAudioFileProperty_CodecManufacturer,
                                      sizeof(codec),
                                      &codec);
        CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileSetProperty kExtAudioFileProperty_CodecManufacturer failed");
        
        err = ExtAudioFileSetProperty(audioFileRef,
                                      kExtAudioFileProperty_ClientDataFormat,
                                      sizeof(audioStreamFormat),
                                      &audioStreamFormat);
        CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed"); */
        
        
       
        OSStatus err;
        AudioStreamBasicDescription destinationFormat;
        _destFormat = destinationFormat;
        
         FillOutASBDForLPCM(destinationFormat,audioStreamFormat.mSampleRate,audioStreamFormat.mChannelsPerFrame,32,32,true,false,false);
        
        [AudioStreamBasicDescriptions printAsbdDif:@"EAudioRenderBufferRecorder" asbdTitle1:@"source format" format1:audioStreamFormat asbdTitle2:@"target format" format2:destinationFormat];
        
        ExtAudioFileRef extAudioFile;
        CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                                (CFStringRef)path,
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
        
    }else if ([ext containsString:@"m4a"]) {
        
        return [self setupAACWriter];
       
      /*  OSType codecManfacturer = kAppleHardwareAudioCodecManufacturer;
        
        OSStatus  status = ExtAudioFileSetProperty(_extAudioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManfacturer);
        
        if (status != noErr)
        {
            SHOW_ERROR(status,"ExtAudioFileSetProperty kExtAudioFileProperty_CodecManufacturer kAppleSoftwareAudioCodecManufacturer failed!! ");
            ExtAudioFileDispose(_extAudioFile);
            return NO;
        }
        
        status = ExtAudioFileSetProperty(_extAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &_clientFormat);
        if (status != noErr) {
            SHOW_ERROR(status,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed!");
            ExtAudioFileDispose(_extAudioFile);
            return NO;
        }
        
        //設置bitrate
        AudioConverterRef audioConverter;
       UInt32 size = sizeof(audioConverter);
        status = ExtAudioFileGetProperty(_extAudioFile, kExtAudioFileProperty_AudioConverter, &size, &audioConverter);
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
        } */
    }else if([ext containsString:@"mp3"]){
        
        _mp3Writer = [[mp3Writer alloc] init];
        if ([_mp3Writer config:path audioSourceFormat:audioStreamFormat]) {
            return YES;
        }
        _mp3Writer = nil;
        
        return NO;
    }
    return true;
    
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
    destinationFormat.mFormatID          = kAudioFormatMPEG4AAC;
    destinationFormat.mFormatFlags       = kMPEG4Object_AAC_Main;
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


-(void)seekToOriginalFileEnd{
    
    if (_mp3Writer) {
        [_mp3Writer seekEndFile];
    }else{
        /*
        SInt64 fileOffset = _audioFileFormat.mSampleRate * (_duration - 0.5);
        SInt64 currentFrame = 0;
        OSStatus status = ExtAudioFileTell(_extAudioFile,&currentFrame);
        status = ExtAudioFileSeek(_extAudioFile,0);
        SHOW_ERROR(status,"ExtAudioFileSeek failed!"); */
    }
}

-(void)resetToOriginalFile{
    if (_mp3Writer) {
         _isReset = true;
        [_mp3Writer resetFile];
    }else{
       // ExtAudioFileSeek(_extAudioFile,_totalFrames);
    }
    [self close];
}


-(OSStatus)pushAudioBuffer:(AudioUnitRenderActionFlags*)ioActionFlags
            AudioTimeStamp:(const AudioTimeStamp *)inTimeStamp
               inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames
           AudioBufferList:(AudioBufferList*)ioData
{
    if(_mp3Writer){
        return [_mp3Writer pushAudioBuffer:inNumberFrames AudioBufferList:ioData];
    }
   else if (_extAudioFile)
    {
        if (_synWrite) {
            return (ExtAudioFileWrite(_extAudioFile, inNumberFrames, ioData));
        }else{
            return (ExtAudioFileWriteAsync(_extAudioFile, inNumberFrames, ioData));
        }
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
        if (!_isReset) {
            [self fillSilence];
        }
        ExtAudioFileDispose(_extAudioFile);
        _extAudioFile = NULL;
    }
    _mp3Writer = nil;
}




-(BOOL)openExAudioFile:(NSString*)filePath{
    
    ExtAudioFileRef audioFileRef;
    AudioFileID audioFileID;
    
    AudioStreamBasicDescription clientFormat = [AudioStreamBasicDescriptions nonInterleavedFloatStereoAudioDescription];
    
    NSURL* url = [NSURL fileURLWithPath:filePath];
    OSStatus err = ExtAudioFileOpenURL((__bridge CFURLRef)url, &audioFileRef);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileOpenURL failed");
    _extAudioFile = audioFileRef;
  //  _clientFormat = clientFormat;
    
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
    
    UInt32 inNumberFrames = 1024;
    UInt32 framesCount = inNumberFrames;
    AudioBufferList *bufferList = AEAllocateAndInitAudioBufferList(clientFormat, inNumberFrames);
    
    
   
    
    while (1) {
        OSStatus status =  ExtAudioFileRead(audioFileRef,
                                            &framesCount,
                                            bufferList);
        CHECK_ERROR_MSG_RET_NO(status,"ExtAudioFileRead audioFileRef failed");
        
        if (self.eaudioReadFileOutputBlock) {
            if (_outFloatData == NULL ) {
                _outFloatData =  (float*)calloc(4096, sizeof(char));
                memset(_outFloatData, 0, sizeof(char)*4096);
            }
            memcpy(_outFloatData, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);
            self.eaudioReadFileOutputBlock(_outFloatData, inNumberFrames);
        }
        
        if (framesCount==0) {
            ExtAudioFileDispose(audioFileRef);
            audioFileRef = nil;
            printf("Done reading from input file\n");
            break;
        }
    }
    return true;
}



+(BOOL)cutFile:(NSString*)inputFilePath  outputFilePath:(NSString*)outputFilePath startTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime durationTime:(NSTimeInterval)durationTime{
    
    ExtAudioFileRef audioFileRef;
    AudioFileID audioFileID;
    
    ExtAudioFileRef outputAudioFileRef;
    
    NSURL* url = [NSURL fileURLWithPath:inputFilePath];
    OSStatus err = ExtAudioFileOpenURL((__bridge CFURLRef)url, &audioFileRef);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileOpenURL failed");
    UInt32 propSize = sizeof(audioFileID);
    err = ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_AudioFile, &propSize, &audioFileID);
    CHECK_ERROR(err,"ExtAudioFileGetProperty kExtAudioFileProperty_AudioFile failed");
    
    AudioStreamBasicDescription audioFileFormat;
    propSize = sizeof(audioFileFormat);
    err = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propSize, &audioFileFormat);
    CHECK_ERROR_MSG_RET_NO(err,"AudioFileGetProperty kAudioFilePropertyDataFormat failed");
    AudioStreamBasicDescription defaultStreamFormat = [AudioStreamBasicDescriptions nonInterleavedFloatStereoAudioDescription];
    
    // Apply client format
    err = ExtAudioFileSetProperty(audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(defaultStreamFormat), &defaultStreamFormat);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed");
    
    [AudioStreamBasicDescriptions printAsbdDif:@"EAudioFile" asbdTitle1:@"audioFile format" format1:audioFileFormat asbdTitle2:@"client format" format2:defaultStreamFormat];
    
     if([outputFilePath containsString:@"mp3"]){
        NSFileManager* fileMgr = [NSFileManager defaultManager];
        if ([fileMgr fileExistsAtPath: inputFilePath ] == NO)
        {
            return NO;
        }
        if ([fileMgr fileExistsAtPath: outputFilePath ]) {
            [fileMgr removeItemAtPath:outputFilePath error:nil];
        }
        [fileMgr createFileAtPath: outputFilePath
                         contents: nil
                       attributes: nil];
        
        NSFileHandle *inputFileHandle = [NSFileHandle fileHandleForReadingAtPath:inputFilePath];
        NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:outputFilePath];
        [outputFileHandle truncateFileAtOffset:0];
        
        [inputFileHandle seekToEndOfFile];
        unsigned long long totalLength = inputFileHandle.offsetInFile;
        unsigned long long perZeroPointOneLength = totalLength / (durationTime*10) ;
        unsigned long long startCount = startTime * 10 * perZeroPointOneLength;
        unsigned long long endCount = endTime * 10 * perZeroPointOneLength;
        
        [inputFileHandle seekToFileOffset:startCount];
        while ( (endCount - startCount) > 1024 *20 ) {
            NSUInteger  length = 1024*20;
            NSData *inData = [inputFileHandle readDataOfLength:length];
            [outputFileHandle writeData:inData];
            startCount = startCount + length;
        }
        if (endCount - startCount != 0) {
            NSUInteger  length = NSUInteger(endCount - startCount);
            NSData *inData = [inputFileHandle readDataOfLength:length];
            [outputFileHandle writeData:inData];
        }
        [outputFileHandle closeFile];
        [inputFileHandle closeFile];
        
        return true;
    }
    
    NSString* ext = [inputFilePath pathExtension];
    AudioFileTypeID fileTypeId = [EAudioMisc AudioFileTypeForExtension: ext ];
    AudioStreamBasicDescription destinationFormat;
    
    
    if (![outputFilePath containsString:@"m4a"]) {
        
        FillOutASBDForLPCM(destinationFormat,defaultStreamFormat.mSampleRate,defaultStreamFormat.mChannelsPerFrame,32,32,true,false,false);
        
        CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                                (CFStringRef)outputFilePath,
                                                                kCFURLPOSIXPathStyle,
                                                                false);
        err = ExtAudioFileCreateWithURL(destinationURL, fileTypeId, &audioFileFormat, NULL, kAudioFileFlags_EraseFile, &outputAudioFileRef);
        CFRelease(destinationURL);
        CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileCreateWithURL failed");
        err = ExtAudioFileSetProperty(outputAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &defaultStreamFormat);
        if (err != noErr) {
            SHOW_ERROR(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed!");
            ExtAudioFileDispose(outputAudioFileRef);
            return NO;
        }
    }else {
        memset(&destinationFormat, 0, sizeof(destinationFormat));
        destinationFormat.mChannelsPerFrame = 2;
        destinationFormat.mSampleRate = defaultStreamFormat.mSampleRate;
        destinationFormat.mFormatID          = kAudioFormatMPEG4AAC;
        destinationFormat.mFormatFlags       = kMPEG4Object_AAC_Main;
        destinationFormat.mFramesPerPacket    = 1024;
        UInt32 size = sizeof(destinationFormat);
        OSStatus status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
        CHECK_ERROR_MSG_RET_NO(status,"AudioFormatGetProperty kAudioFormatProperty_FormatInfo failed");
        
        status = ExtAudioFileCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:outputFilePath],
                                           kAudioFileM4AType,
                                           &destinationFormat,
                                           NULL,
                                           kAudioFileFlags_EraseFile,
                                           &outputAudioFileRef);
        
        err = ExtAudioFileSetProperty(outputAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &defaultStreamFormat);
        if (err != noErr) {
            SHOW_ERROR(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed!");
            ExtAudioFileDispose(outputAudioFileRef);
            return NO;
        }
        
        //設置bitrate
        AudioConverterRef audioConverter;
        size = sizeof(audioConverter);
        status = ExtAudioFileGetProperty(outputAudioFileRef, kExtAudioFileProperty_AudioConverter, &size, &audioConverter);
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
        
    }
    UInt32 inNumberFrames = 1024;
    UInt32 perPackSize = inNumberFrames * 4;
    AudioBufferList *bufferList = AEAllocateAndInitAudioBufferList(defaultStreamFormat, inNumberFrames);
    
    SInt64 fileOffset = audioFileFormat.mSampleRate * (startTime);
    unsigned long long allFrameCount = audioFileFormat.mSampleRate*(endTime - startTime);
    unsigned long long readFrameCount = 0;
    ExtAudioFileSeek(audioFileRef, fileOffset);
    while (readFrameCount < allFrameCount) {
        
        UInt32 framesCount = inNumberFrames;
        if (audioFileRef) {
            OSStatus status =  ExtAudioFileRead(audioFileRef,
                                                &framesCount,
                                                bufferList);
            CHECK_ERROR_MSG_RET_NO(status,"ExtAudioFileRead audioFileRef failed");
            
            readFrameCount = readFrameCount + framesCount;
            if (framesCount==0) {
                ExtAudioFileDispose(audioFileRef);
                audioFileRef = nil;
                UInt32 mNumberBuffers = defaultStreamFormat.mChannelsPerFrame;
                for ( int i=0; i<mNumberBuffers; i++ ) {
                    bufferList->mBuffers[i].mDataByteSize = perPackSize;
                }
                printf("Done reading from input file\n");
            }
        }
        OSStatus status = ExtAudioFileWrite(outputAudioFileRef,
                                            framesCount,
                                            bufferList);
        CHECK_ERROR_MSG_RET_NO(status,"ExtAudioFileWrite outputAudioFileRef failed");
        
        
    }
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSDictionary<NSString *, id>* dict = [fileMgr attributesOfItemAtPath:outputFilePath error:NULL];
    
    if(dict != nil){
        float size = [dict fileSize] / 1024.0;
        NSLog(@",%@,size:%.2fKb ",outputFilePath,size);
    }
    ExtAudioFileDispose(outputAudioFileRef);
    outputAudioFileRef = nil;
    AEFreeAudioBufferList(bufferList);
    ExtAudioFileDispose(audioFileRef);
    audioFileRef = nil;
    return true;
}


/**
  两个音频文件合成一个音频文件
 */
+(BOOL)appendTwoFile:(NSString*)firstFilePath secondFilePath:(NSString*)secondFilePath outputFilePath:(NSString*)outputFilePath{
    
    ExtAudioFileRef audioFileRef;
    AudioFileID audioFileID;
    
    ExtAudioFileRef audioFileRef2;
    
    ExtAudioFileRef outputAudioFileRef;
    
    NSURL* url = [NSURL fileURLWithPath:firstFilePath];
    OSStatus err = ExtAudioFileOpenURL((__bridge CFURLRef)url, &audioFileRef);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileOpenURL failed");
    UInt32 propSize = sizeof(audioFileID);
    err = ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_AudioFile, &propSize, &audioFileID);
    CHECK_ERROR(err,"ExtAudioFileGetProperty kExtAudioFileProperty_AudioFile failed");
    
    AudioStreamBasicDescription audioFileFormat;
    propSize = sizeof(audioFileFormat);
    err = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propSize, &audioFileFormat);
    CHECK_ERROR_MSG_RET_NO(err,"AudioFileGetProperty kAudioFilePropertyDataFormat failed");
     AudioStreamBasicDescription defaultStreamFormat = [AudioStreamBasicDescriptions nonInterleavedFloatStereoAudioDescription];

    // Apply client format
    err = ExtAudioFileSetProperty(audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(defaultStreamFormat), &defaultStreamFormat);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed");
    
    [AudioStreamBasicDescriptions printAsbdDif:@"EAudioFile" asbdTitle1:@"audioFile format" format1:audioFileFormat asbdTitle2:@"client format" format2:defaultStreamFormat];
    
    
    NSURL* url2 = [NSURL fileURLWithPath:secondFilePath];
    err = ExtAudioFileOpenURL((__bridge CFURLRef)url2, &audioFileRef2);
    CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileOpenURL2 failed");
    // Apply client format
    defaultStreamFormat = [AudioStreamBasicDescriptions nonInterleavedFloatStereoAudioDescription];
    err = ExtAudioFileSetProperty(audioFileRef2, kExtAudioFileProperty_ClientDataFormat, sizeof(defaultStreamFormat), &defaultStreamFormat);
    
    
    NSString* ext = [secondFilePath pathExtension];
    AudioFileTypeID fileTypeId = [EAudioMisc AudioFileTypeForExtension: ext ];
    AudioStreamBasicDescription destinationFormat;

    if (![outputFilePath containsString:@"m4a"]) {
        
        FillOutASBDForLPCM(destinationFormat,defaultStreamFormat.mSampleRate,defaultStreamFormat.mChannelsPerFrame,32,32,true,false,false);
        
        CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                                (CFStringRef)outputFilePath,
                                                                kCFURLPOSIXPathStyle,
                                                                false);
        err = ExtAudioFileCreateWithURL(destinationURL, fileTypeId, &audioFileFormat, NULL, kAudioFileFlags_EraseFile, &outputAudioFileRef);
        CFRelease(destinationURL);
        CHECK_ERROR_MSG_RET_NO(err,"ExtAudioFileCreateWithURL failed");
        err = ExtAudioFileSetProperty(outputAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &defaultStreamFormat);
        if (err != noErr) {
            SHOW_ERROR(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed!");
            ExtAudioFileDispose(outputAudioFileRef);
            return NO;
        }
    }else {
        memset(&destinationFormat, 0, sizeof(destinationFormat));
        destinationFormat.mChannelsPerFrame = 2;
        destinationFormat.mSampleRate = defaultStreamFormat.mSampleRate;
        destinationFormat.mFormatID          = kAudioFormatMPEG4AAC;
        destinationFormat.mFormatFlags       = kMPEG4Object_AAC_Main;
        destinationFormat.mFramesPerPacket    = 1024;
        UInt32 size = sizeof(destinationFormat);
        OSStatus status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
        CHECK_ERROR_MSG_RET_NO(status,"AudioFormatGetProperty kAudioFormatProperty_FormatInfo failed");
        
        status = ExtAudioFileCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:outputFilePath],
                                           kAudioFileM4AType,
                                           &destinationFormat,
                                           NULL,
                                           kAudioFileFlags_EraseFile,
                                           &outputAudioFileRef);
        
        err = ExtAudioFileSetProperty(outputAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &defaultStreamFormat);
        if (err != noErr) {
            SHOW_ERROR(err,"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed!");
            ExtAudioFileDispose(outputAudioFileRef);
            return NO;
        }
        
        //設置bitrate
        AudioConverterRef audioConverter;
        size = sizeof(audioConverter);
        status = ExtAudioFileGetProperty(outputAudioFileRef, kExtAudioFileProperty_AudioConverter, &size, &audioConverter);
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
        
    }

    UInt32 inNumberFrames = 1024;
    UInt32 perPackSize = inNumberFrames * 4;
    AudioBufferList *bufferList = AEAllocateAndInitAudioBufferList(defaultStreamFormat, inNumberFrames);
   
    while (1) {
        
        UInt32 framesCount = inNumberFrames;
        if (audioFileRef) {
           OSStatus status =  ExtAudioFileRead(audioFileRef,
                             &framesCount,
                             bufferList);
            CHECK_ERROR_MSG_RET_NO(status,"ExtAudioFileRead audioFileRef failed");

            if (framesCount==0) {
                ExtAudioFileDispose(audioFileRef);
                audioFileRef = nil;
                UInt32 mNumberBuffers = defaultStreamFormat.mChannelsPerFrame;
                for ( int i=0; i<mNumberBuffers; i++ ) {
                    bufferList->mBuffers[i].mDataByteSize = perPackSize;
                }
                printf("Done reading from input file\n");
            }
        }else{
            OSStatus status = ExtAudioFileRead(audioFileRef2,
                             &framesCount,
                             bufferList);
            CHECK_ERROR_MSG_RET_NO(status,"ExtAudioFileRead audioFileRef2 failed");
            if (framesCount==0) {
                ExtAudioFileDispose(audioFileRef2);
                audioFileRef2 = nil;
                printf("Done reading from input file\n");
                break;
            }
        }
       OSStatus status = ExtAudioFileWrite(outputAudioFileRef,
                          framesCount,
                          bufferList);
        CHECK_ERROR_MSG_RET_NO(status,"ExtAudioFileWrite outputAudioFileRef failed");

 
    }
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSDictionary<NSString *, id>* dict = [fileMgr attributesOfItemAtPath:outputFilePath error:NULL];
    NSDictionary<NSString *, id>* dict2 = [fileMgr attributesOfItemAtPath:secondFilePath error:NULL];

    if(dict != nil){
        float size = [dict fileSize] / 1024.0;
        NSLog(@",%@,size:%.2fKb   secondFilePath:%@  size:%.2fKb",outputFilePath,size,secondFilePath,[dict2 fileSize] / 1024.0);
    }
    ExtAudioFileDispose(outputAudioFileRef);
    outputAudioFileRef = nil;
    AEFreeAudioBufferList(bufferList);
    return true;
}



@end

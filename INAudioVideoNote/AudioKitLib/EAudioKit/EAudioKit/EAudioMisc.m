//
//  EAudioMisc.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioMisc.h"
#import "EAMicro.h"
#import <sys/utsname.h>

static inline BOOL isiPhone8(){
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([code rangeOfString:@"iPhone10"].length > 0) {
//        @"iPhone10,1" : @(iPhone8),
//        @"iPhone10,4" : @(iPhone8),
//        @"iPhone10,2" : @(iPhone8Plus),
//        @"iPhone10,5" : @(iPhone8Plus),
//        @"iPhone10,3" : @(iPhoneX),
//        @"iPhone10,6" : @(iPhoneX),
        return YES;
    }
    return NO;
}

static inline NSUInteger AudioSampleRate(){
    NSUInteger samplerate = 44100;
    if (isiPhone8()) {
        samplerate = 48000;
    }
    return samplerate;
}


@implementation EAudioMisc

+ (AudioFileTypeID)AudioFileTypeForExtension:(NSString *)fileExtension
{
    
    AudioFileTypeID fileTypeHint = kAudioFileMPEG4Type;
    if ([fileExtension isEqual:@"mp3"])
    {
        fileTypeHint = kAudioFileMP3Type;
    }
    else if ([fileExtension isEqual:@"wav"])
    {
        fileTypeHint = kAudioFileWAVEType;
    }
    else if ([fileExtension isEqual:@"aifc"])
    {
        fileTypeHint = kAudioFileAIFCType;
    }
    else if ([fileExtension isEqual:@"aiff"])
    {
        fileTypeHint = kAudioFileAIFFType;
    }
    else if ([fileExtension isEqual:@"m4a"])
    {
        fileTypeHint = kAudioFileM4AType;
    }
    else if ([fileExtension isEqual:@"mp4"])
    {
        fileTypeHint = kAudioFileMPEG4Type;
    }
    else if ([fileExtension isEqual:@"caf"])
    {
        fileTypeHint = kAudioFileCAFType;
    }
    else if ([fileExtension isEqual:@"aac"])
    {
        fileTypeHint = kAudioFileAAC_ADTSType;
    }
    return fileTypeHint;
}

+ (AudioFormatID) AudioFormatIDForExtension:(NSString *)fileExtension
{
    AudioFormatID formatId = kAudioFormatMPEG4AAC;
    if ([fileExtension isEqual:@"mp3"])
    {
        formatId = kAudioFormatMPEGLayer3;
    }
    else if ([fileExtension isEqual:@"mp4"])
    {
        formatId = kAudioFormatMPEG4AAC;
    }
    return formatId;
}


/*+ (BOOL)hasHeadset
{
    CFStringRef route;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute,&propertySize, &route);
    if((route ==NULL) || (CFStringGetLength(route) == 0)){
        // Silent Mode
        NSLog(@"AudioRoute: SILENT, do nothing!");
    } else{
        NSString* routeStr = (__bridge NSString*)route;
        NSLog(@"AudioRoute: %@", routeStr);
        
        NSRange headphoneRange = [routeStr rangeOfString :@"Headphone"];
        NSRange headsetRange = [routeStr rangeOfString : @"Headset"];
        if (headphoneRange.location != NSNotFound) {
            return YES;
        } else if(headsetRange.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
    
} */


+ (BOOL)hasHeadset {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
        else if ([[desc portType] isEqualToString:AVAudioSessionPortHeadsetMic]){
            return YES ;
        }
    }
    return NO;
}


+ (void)fillSilence:(AudioBufferList*)ioData
{
    for(int i=0; i < ioData->mNumberBuffers; i++)
    {
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
}
+(BOOL)AACEncodingAvailable
{
    return [EAudioMisc AACEncodingAvailable:NULL];
}

+(BOOL)AACEncodingAvailable:(OSType*) audioCodecManufacturer
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    static BOOL g_available;
    static BOOL g_available_set = NO;
    static OSType g_audioCodecManufacturer = 0;
    if ( g_available_set ) {
        if(g_available && audioCodecManufacturer){
            *audioCodecManufacturer = g_audioCodecManufacturer;
        }
        return g_available;
    }
    
    // get an array of AudioClassDescriptions for all installed encoders for the given format
    // the specifier is the format that we are interested in - this is 'aac ' in our case
    UInt32 encoderSpecifier = kAudioFormatMPEG4AAC;
    UInt32 size;
    OSStatus err = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    CHECK_ERROR_MSG_RET_NO(err, "AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders")
    
    UInt32 numEncoders = size / sizeof(AudioClassDescription);
    AudioClassDescription encoderDescriptions[numEncoders + 1];
    err = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, encoderDescriptions);
    CHECK_ERROR(err, "AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders")
    if ( err != noErr) {
        g_available_set = YES;
        g_available = NO;
        return NO;
    }
    
    for (UInt32 i=0; i < numEncoders; ++i) {
        if ( encoderDescriptions[i].mSubType == kAudioFormatMPEG4AAC  )
        {
            
            if (encoderDescriptions[i].mManufacturer == kAppleSoftwareAudioCodecManufacturer ||
                encoderDescriptions[i].mManufacturer == kAppleHardwareAudioCodecManufacturer)
            {
                
                if(audioCodecManufacturer){
                    *audioCodecManufacturer = encoderDescriptions[i].mManufacturer;
                }
                g_audioCodecManufacturer = encoderDescriptions[i].mManufacturer;
                g_available_set = YES;
                g_available = YES;
                return YES;
            }
            
        }
    }
    
    g_available_set = YES;
    g_available = NO;
    return NO;
#endif
}

@end

NSMutableDictionary* g_insTracker = nil;
@implementation EAInstaceTracker

+ (void)addInstace:(id)ins
{
    if (g_insTracker == nil) {
        g_insTracker = [[NSMutableDictionary alloc] init];
    }
    NSString* name = NSStringFromClass([ins class]);
    NSNumber* count = g_insTracker[name];
    if (count == nil) {
        count = [NSNumber numberWithInt:1];
        g_insTracker[name] = count;
    }else{
        g_insTracker[name] = [NSNumber numberWithInt:count.integerValue + 1];
    }
    
}
+ (void)removeInstance:(id)ins
{
    if (g_insTracker == nil)
        return;
    
    NSString* name = NSStringFromClass([ins class]);
    NSNumber* count = g_insTracker[name];
    if (count == nil) {
        NSLog(@"EAInstaceTracker Ref err,%@",name);
    }else{
        int c = count.integerValue - 1;
        if (c == 0) {
            [g_insTracker removeObjectForKey:name];
        }else{
            g_insTracker[name] = [NSNumber numberWithInt:c];
        }
    }
}
+ (void)printInstance
{
    NSLog(@"\n\n---------------------EAInstaceTracker---------------------");
    if ([g_insTracker count] == 0) {
        NSLog(@"no instance ref,clear...");
    }else{
        NSLog(@"WARNING:\n\n\n%@",g_insTracker);
    }
    NSLog(@"---------------------------------------------------------------\n\n");
    
}
@end


@implementation AudioStreamBasicDescriptions



+ (AudioStreamBasicDescription)interleaved16BitStereoAudioDescription {
    AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = sizeof(SInt16)*audioDescription.mChannelsPerFrame;
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(SInt16)*audioDescription.mChannelsPerFrame;
    audioDescription.mBitsPerChannel    = 8 * sizeof(SInt16);
    audioDescription.mSampleRate        = AudioSampleRate();
    return audioDescription;
}

+ (AudioStreamBasicDescription)nonInterleaved16BitStereoAudioDescription {
    AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsNonInterleaved;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = sizeof(SInt16);
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(SInt16);
    audioDescription.mBitsPerChannel    = 8 * sizeof(SInt16);
    audioDescription.mSampleRate        = AudioSampleRate();
    return audioDescription;
}

+ (AudioStreamBasicDescription)nonInterleavedFloatStereoAudioDescription {
    AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved ;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = sizeof(float);
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(float);
    audioDescription.mBitsPerChannel    = 8 * sizeof(float);
    audioDescription.mSampleRate        = AudioSampleRate();
    return audioDescription;
}


+ (AudioStreamBasicDescription)nonInterleavedFloatStereoAudioDescriptionKTV {
    
    
    AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked |kAudioFormatFlagIsNonInterleaved ;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = sizeof(float);
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(float);
    audioDescription.mBitsPerChannel    = 8 * sizeof(float);
    audioDescription.mSampleRate        = AudioSampleRate();
    return audioDescription;
    
  /*  AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = sizeof(SInt16);
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(SInt16);
    audioDescription.mBitsPerChannel    = 8 * sizeof(SInt16);
    audioDescription.mSampleRate        = 44100.0;
    return audioDescription; */
    
    
    
    
     AudioStreamBasicDescription desc = {0};
     desc.mSampleRate = AudioSampleRate();
     
     desc.mFormatID = kAudioFormatLinearPCM;
     desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked ;
     desc.mChannelsPerFrame = 1;
     desc.mFramesPerPacket = 1;
     desc.mBitsPerChannel = 16;
     desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
     desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    
     return desc;
    
}


+ (AudioStreamBasicDescription)nonInterleavedS16BitStereoAudioDescription {
    
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = AudioSampleRate();
    
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked ;
    desc.mChannelsPerFrame = 1;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = 16;
    desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    
    return desc;
    
}

+ (AudioStreamBasicDescription)nonInterleaved32BitStereoAudioDescription
{
    UInt32 bytesPerSample = sizeof(SInt32);//sizeof (AudioUnitSampleType);
    AudioStreamBasicDescription stereoStreamFormat;
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mSampleRate        = AudioSampleRate();
    return stereoStreamFormat;
}

+(NSString*) formatASBD: (AudioStreamBasicDescription) asbd {
    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSMutableString* flag = [[NSMutableString alloc] init];
    if(asbd.mFormatFlags & kAudioFormatFlagIsFloat)
       [flag appendFormat:@"kAudioFormatFlagIsFloat|"];
    if(asbd.mFormatFlags & kAudioFormatFlagIsSignedInteger)
        [flag appendFormat:@"kAudioFormatFlagIsSignedInteger|"];
    if(asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved)
        [flag appendFormat:@"kAudioFormatFlagIsNonInterleaved|"];
    if(asbd.mFormatFlags & kAudioFormatFlagIsBigEndian)
        [flag appendFormat:@"kAudioFormatFlagIsBigEndian|"];
    if(asbd.mFormatFlags & kAudioFormatFlagIsPacked)
        [flag appendFormat:@"kAudioFormatFlagIsPacked|"];
    if(asbd.mFormatFlags & kAudioFormatFlagIsAlignedHigh)
        [flag appendFormat:@"kAudioFormatFlagIsAlignedHigh|"];
    if(asbd.mFormatFlags & kAudioFormatFlagIsNonMixable)
        [flag appendFormat:@"kAudioFormatFlagIsNonMixable"];

    
    
    NSMutableString* format = [[NSMutableString alloc] init];
    [format appendFormat:@"    Sample Rate:         %10.0f\n",  asbd.mSampleRate];
    [format appendFormat:@"    Format ID:           %10s\n",    formatIDString];
    [format appendFormat:@"    Format Flags:        %10u(%@)\n",  (unsigned int)asbd.mFormatFlags,flag];
    [format appendFormat:@"    Bytes per Packet:    %10u\n",    (unsigned int)asbd.mBytesPerPacket];
    [format appendFormat:@"    Frames per Packet:   %10u\n",    (unsigned int)asbd.mFramesPerPacket];
    [format appendFormat:@"    Bytes per Frame:     %10u\n",    (unsigned int)asbd.mBytesPerFrame];
    [format appendFormat:@"    Channels per Frame:  %10u\n",    (unsigned int)asbd.mChannelsPerFrame];
    [format appendFormat:@"    Bits per Channel:    %10u\n",    (unsigned int)asbd.mBitsPerChannel];
    return format;
}

+(void) printASBD: (AudioStreamBasicDescription) asbd {
    
    NSLog(@"\n%@",[AudioStreamBasicDescriptions formatASBD:asbd]);
}

+ (void) printAsbdDif:(NSString*)title asbdTitle1:(NSString*)t1 format1:(AudioStreamBasicDescription)f1 asbdTitle2:(NSString*)t2 format2:(AudioStreamBasicDescription)f2
{
    NSMutableString* format = [[NSMutableString alloc] init];
    [format appendFormat:@"\n----------------%@----------------",title];
    [format appendFormat:@"\n%@:\n%@",t1,[AudioStreamBasicDescriptions formatASBD:f1]];
    [format appendFormat:@"\n%@:\n%@",t2,[AudioStreamBasicDescriptions formatASBD:f2]];
    [format appendString:@"\n-----------------------------------"];
    NSLog(@"%@",format);
}
@end

////////////////////////////////////////////////////////////////////////////////
//////////////////////EATimeSlapsTracer/////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static int g_EATimeSlapsTracer_level = -1;
static NSMutableString* g_EATimeSlapsTracer_report = nil;
static BOOL g_EATimeSlapsTracer_warning;
@interface EATimeSlapsTracer()
{
    NSString*       _name;
    NSTimeInterval _tickBegin;
    float          _threshold;
    int            _level;
}

@end

@implementation EATimeSlapsTracer


-(instancetype)initWithName:(NSString*)name withThreshold:(float)threshold
{
    self = [super init];
    _name = name;
    _tickBegin = [NSDate timeIntervalSinceReferenceDate];
    _threshold = threshold;
    
    g_EATimeSlapsTracer_level ++;
    _level = g_EATimeSlapsTracer_level;
    if (_level == 0) {
        g_EATimeSlapsTracer_warning = NO;
        g_EATimeSlapsTracer_report = [[NSMutableString alloc] initWithCapacity:512];
    }
    return self;
}

-(void)dealloc
{
    [self report];
    g_EATimeSlapsTracer_level--;
    if (_level == 0 && g_EATimeSlapsTracer_warning) {
        NSMutableString* format = [[NSMutableString alloc] initWithCapacity:512];
        [format appendString:@"\n\n-------------------EATimeSlapsTracer-------------------\n"];
        [format appendFormat:@"%@\n\n",g_EATimeSlapsTracer_report ];
        NSLog(@"%@",format);
    }
}

-(void)report
{
#ifdef DEBUG  //testliurg
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval slaps = now - _tickBegin;
    NSString* space = [self getSpace:_level];
    if (space == nil) {
        return ;
    }
    [g_EATimeSlapsTracer_report appendFormat:@"%@%@:%.02fms slaps",space,_name,slaps*1000 ];
    if (slaps >= _threshold) {
        g_EATimeSlapsTracer_warning = YES;
        [g_EATimeSlapsTracer_report appendFormat:@" warning(threshold:%0.2fms)",_threshold * 1000 ];
    }
    [g_EATimeSlapsTracer_report appendString:@"\n" ];
    
#endif

}

-(NSString*)getSpace:(int)n
{
    NSMutableString* space = [[NSMutableString alloc] initWithCapacity:512];
    n = n * 10;
    for(int i = 0; i< n; i++)
    {
        [space appendString:@" "];
    }
    NSString* r = space;
    return r;
}

@end


////////////////////////////////////////////////////////////////////////////////
//////////////////////EAInvokeFreq/////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface EAInvokeFreq()
{
    NSTimeInterval _begin;
    UInt64         _count;
    NSTimeInterval _beginRef;
}
@end
@implementation EAInvokeFreq
-(instancetype)initWithName:(NSString*)name
{
    self = [super init];
    _name = name;
    _freq = 0;
    _begin = 0;
    return self;
}


-(void)invoke
{
    [self invokeImp:YES];
}
-(void)invokeSilence
{
    [self invokeImp:NO];
}

-(void)invokeImp:(BOOL)print
{
    if (_begin == 0) {
        _begin = [NSDate timeIntervalSinceReferenceDate];
        _beginRef = _begin;
        _count = 1;
    }else{
        _count++;
        if (print)
        {
            NSTimeInterval cur = [NSDate timeIntervalSinceReferenceDate];
            NSTimeInterval slaps = cur - _beginRef;
            if (slaps > 1) {
                _beginRef = cur;
                slaps = cur - _begin;
                _freq = _count / slaps;
                NSLog(@"EAInvokeFreq:%@,freq:%0.4fn/s,count:%llu,slaps:%0.2fs",_name,_freq,_count,slaps);
            }
        }
    }
}

-(void)calc:(BOOL)print
{
    
}

-(void)print
{
    NSTimeInterval cur = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval slaps = cur - _begin;
    NSLog(@"EAInvokeFreq:%@,freq:%0.2fn/s,count:%llu,slaps:%0.2fs",_name,_freq,_count,slaps);
}

@end


@interface EACircleBuffer()
{
    void*   _buffer;
    void*   _cacheBuffer;
    int     _bufferSize;
    int     _dataSize;
    int     _dataPosHead,_dataPosTail;
}
@end
@implementation EACircleBuffer

-(instancetype) initWithBufferSize:(int)bufferSize
{
    self = [super init];
    _buffer = malloc(bufferSize);
    _cacheBuffer = malloc(bufferSize);
    _bufferSize = bufferSize;
    _dataPosHead = 0;
    _dataPosTail = 0;
    _dataSize = 0;
    return self;
}

-(void)dealloc
{
    free(_buffer);
    _buffer = 0;
    
    free(_cacheBuffer);
    _cacheBuffer = NULL;
}

-(int)pushData:(void*)data dataByteSize:(int)size
{
    int len = MIN(size, _bufferSize - _dataSize);
    if (len <= 0) {
        return 0;
    }
    
    int len1 = len;
    int len2 = 0;
    if (_dataPosTail + len > _bufferSize) {
        len2 = _dataPosTail + len - _bufferSize;
        len1 = len - len2;
    }
    memcpy((char*)_buffer + _dataPosTail, data, len1);
    _dataPosTail += len1;
    if (_dataPosTail >= _bufferSize) {
        assert(_dataPosTail == _bufferSize);
        _dataPosTail = 0;
    }
    if (len2 > 0) {
        memcpy((char*)_buffer + _dataPosTail, (char*)data + len1, len2);
        _dataPosTail += len2;
    }
    _dataSize += len;
    return len;
}
-(int)popData:(void*)data dataByteSize:(int)size
{
    int len = MIN(size, _dataSize);
    if (len <= 0) {
        return 0;
    }

    int len1 = len;
    int len2 = 0;
    if (_dataPosHead + len > _bufferSize) {
        len2 = _dataPosHead + len - _bufferSize;
        len1 = len - len2;
    }
    memcpy(data, (char*)_buffer + _dataPosHead, len1);
    _dataPosHead += len1;
    
    if (_dataPosHead >= _bufferSize) {
        assert(_dataPosHead == _bufferSize);
        _dataPosHead = 0;
    }
    
    if (len2 > 0) {
        memcpy((char*)data + len1, (char*)_buffer + _dataPosHead, len2);
        _dataPosHead += len2;
    }
    
    _dataSize -= len;
    
    return len;
}

-(int)cacheData:(void*)data dataByteSize:(int)size
{
    int len = MIN(size,_bufferSize);
    memcpy(_cacheBuffer, data, len);
    return len;
}

-(void*)getCacheData
{
    return _cacheBuffer;
}
@end


////////////////////////////////////////////////////////
// convert sample vector from fixed point 8.24 to SInt16
void fixedPointToSInt16( SInt32 * source, SInt16 * target, int length ) {
    
    int i;
    
    for(i = 0;i < length; i++ ) {
        target[i] =  (SInt16) (source[i] >> 9);
        
    }
    
}

////////////////////////////////////////////////////////
// convert sample vector from SInt16 to fixed point 8.24
void SInt16ToFixedPoint( SInt16 * source, SInt32 * target, int length ) {
    
    int i;
    
    for(i = 0;i < length; i++ ) {
        target[i] =  (SInt32) (source[i] << 9);
        if(source[i] < 0) {
            target[i] |= 0xFF000000;
        }
        else {
            target[i] &= 0x00FFFFFF;
        }
        
    }
    
}

void floatToSInt16(float* source,SInt16* target,int samples)
{
    for(int i = 0;i < samples; i++ ) {
        int v = source[i] * 32768 ;
        if( v > 32767 ) v = 32767;
        if( v < -32768 ) v = -32768;
        target[i] = v;
    }
}

void SInt16ToFloat(SInt16* source,float* target,int samples)
{
    for(int i = 0;i < samples; i++ ) {
        target[i] = source[i] / 32768.0 ;
    }
}

AudioBufferList* allocAudioBufferList(AudioStreamBasicDescription audioFormat,int channelFrameCount)
{
    UInt32 bufferSize = sizeof(AudioBufferList) + sizeof(AudioBuffer)* (audioFormat.mChannelsPerFrame - 1);
    AudioBufferList* bufferList = (AudioBufferList*)malloc( bufferSize );
    bufferList->mNumberBuffers = audioFormat.mChannelsPerFrame;
    for (int i=0; i < bufferList->mNumberBuffers; i++) {
        AudioBuffer* buffer = &(bufferList->mBuffers[i]);
        buffer->mDataByteSize = audioFormat.mBytesPerFrame * channelFrameCount;
        buffer->mData = malloc(buffer->mDataByteSize);
        buffer->mNumberChannels = (audioFormat.mFormatFlags & kLinearPCMFormatFlagIsNonInterleaved) ? 1 :channelFrameCount;
    }
    
    return bufferList;
}

void freeAudioBufferList(AudioBufferList* bufferList)
{
    if (bufferList) {
        for (int i=0; i < bufferList->mNumberBuffers; i++) {
            AudioBuffer* buffer = &(bufferList->mBuffers[i]);
            free(buffer->mData);
        }
        free(bufferList);
    }
}

AudioBufferList* monitorBufferList(char* tempBuffer,AudioBufferList* bufferList,int framePos,int frameSize)
{
    AudioBufferList* wrap = (AudioBufferList*)tempBuffer;
    wrap->mNumberBuffers = bufferList->mNumberBuffers;
    for(int i=0; i< bufferList->mNumberBuffers; i++)
    {
        int size = framePos * frameSize;
        wrap->mBuffers[i].mNumberChannels = bufferList->mBuffers[i].mNumberChannels;
        wrap->mBuffers[i].mData = (char*)(bufferList->mBuffers[i].mData) + size;
        wrap->mBuffers[i].mDataByteSize = bufferList->mBuffers[i].mDataByteSize - size;
    }
    return (AudioBufferList*)tempBuffer;
}

AudioBufferList* cloneBufferList(AudioBufferList* bufferList)
{
    AudioBufferList* clone = (AudioBufferList*)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * (bufferList->mNumberBuffers - 1));
    clone->mNumberBuffers = bufferList->mNumberBuffers;
    for(int i=0; i< bufferList->mNumberBuffers; i++)
    {
        UInt32 byteSize = bufferList->mBuffers[i].mDataByteSize;
        clone->mBuffers[i].mNumberChannels = bufferList->mBuffers[i].mNumberChannels;
        clone->mBuffers[i].mDataByteSize = byteSize;
        clone->mBuffers[i].mData = malloc(byteSize);
        memcpy(clone->mBuffers[i].mData, bufferList->mBuffers[i].mData, byteSize);
    }
    return clone;
}


AudioBufferList *AEAudioBufferListCreate(AudioStreamBasicDescription audioFormat, int frameCount) {
    int numberOfBuffers = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? audioFormat.mChannelsPerFrame : 1;
    int channelsPerBuffer = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : audioFormat.mChannelsPerFrame;
    int bytesPerBuffer = audioFormat.mBytesPerFrame * frameCount;
    
    AudioBufferList *audio = (AudioBufferList*)malloc(sizeof(AudioBufferList) + (numberOfBuffers-1)*sizeof(AudioBuffer));
    if ( !audio ) {
        return NULL;
    }
    audio->mNumberBuffers = numberOfBuffers;
    for ( int i=0; i<numberOfBuffers; i++ ) {
        if ( bytesPerBuffer > 0 ) {
            audio->mBuffers[i].mData = calloc(bytesPerBuffer, 1);
            if ( !audio->mBuffers[i].mData ) {
                for ( int j=0; j<i; j++ ) free(audio->mBuffers[j].mData);
                free(audio);
                return NULL;
            }
        } else {
            audio->mBuffers[i].mData = NULL;
        }
        audio->mBuffers[i].mDataByteSize = bytesPerBuffer;
        audio->mBuffers[i].mNumberChannels = channelsPerBuffer;
    }
    return audio;
}



int getAudioFormatType(AudioStreamBasicDescription audioFormat)
{
    int sampleType = SAMPLE_TYPE_UNKNOW;
    if(audioFormat.mFormatFlags & kLinearPCMFormatFlagIsFloat ){
        sampleType = SAMPLE_TYPE_flOAT;
    }else if(audioFormat.mFormatFlags  & kLinearPCMFormatFlagIsSignedInteger){
        if (audioFormat.mBytesPerFrame == 4) {
            sampleType = SAMPLE_TYPE_INT32;

        }else if(audioFormat.mBytesPerFrame == 2){
            sampleType = SAMPLE_TYPE_INT16;
        }
    }
    return sampleType;
}

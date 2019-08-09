//
//  EAudioMisc.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#ifdef DEBUG
    #define DEBUG_LOG NSLog
#else
    #define DEBUG_LOG //
#endif

@interface EAudioMisc : NSObject

+ (AudioFileTypeID)AudioFileTypeForExtension:(NSString *)fileExtension;

+ (AudioFormatID) AudioFormatIDForExtension:(NSString *)fileExtension;

+ (BOOL)hasHeadset;

+ (void)fillSilence:(AudioBufferList*)ioData;

+(BOOL)AACEncodingAvailable;
+(BOOL)AACEncodingAvailable:(OSType*) audioCodecManufacturer;

@end


@interface EAInstaceTracker : NSObject
+ (void)addInstace:(id)ins;
+ (void)removeInstance:(id)ins;
+ (void)printInstance;
@end

@interface AudioStreamBasicDescriptions : NSObject
+ (AudioStreamBasicDescription)interleaved16BitStereoAudioDescription;
+ (AudioStreamBasicDescription)nonInterleaved16BitStereoAudioDescription;
+ (AudioStreamBasicDescription)nonInterleavedFloatStereoAudioDescription;
+ (AudioStreamBasicDescription)nonInterleaved32BitStereoAudioDescription;

+ (AudioStreamBasicDescription)nonInterleavedFloatStereoAudioDescriptionKTV;
+ (AudioStreamBasicDescription)nonInterleavedS16BitStereoAudioDescription;


+ (void) printASBD: (AudioStreamBasicDescription) asbd;
+ (NSString*) formatASBD: (AudioStreamBasicDescription) asbd ;
+ (void) printAsbdDif:(NSString*)title asbdTitle1:(NSString*)t1 format1:(AudioStreamBasicDescription)f1 asbdTitle2:(NSString*)t2 format2:(AudioStreamBasicDescription)f2;
@end

@interface EATimeSlapsTracer : NSObject
-(instancetype)initWithName:(NSString*)name withThreshold:(float)threshold;
@end


@interface EAInvokeFreq : NSObject
@property (nonatomic,strong)   NSString*    name;
@property (nonatomic,readonly) float        freq;
-(instancetype)initWithName:(NSString*)name;
-(void)invoke;
-(void)invokeSilence;
-(void)print;
@end


@interface EACircleBuffer : NSObject
-(instancetype) initWithBufferSize:(int)bufferSize;

//FIFO
-(int)pushData:(void*)data dataByteSize:(int)size;
-(int)popData:(void*)data dataByteSize:(int)size;

-(int)cacheData:(void*)data dataByteSize:(int)size;
-(void*)getCacheData;
@end


////////////////////////////////////////////////////////
// convert sample vector from fixed point 8.24 to SInt16
void fixedPointToSInt16( SInt32 * source, SInt16 * target, int length );
////////////////////////////////////////////////////////
// convert sample vector from SInt16 to fixed point 8.24
void SInt16ToFixedPoint( SInt16 * source, SInt32 * target, int length );

void floatToSInt16(float* source,SInt16* target,int samples);
void SInt16ToFloat(SInt16* source,float* target,int samples);

AudioBufferList* allocAudioBufferList(AudioStreamBasicDescription audioFormat,int channelFrameCount);
void freeAudioBufferList(AudioBufferList*);
AudioBufferList* monitorBufferList(char* tempBuffer,AudioBufferList* bufferList,int framePos,int frameSize);
AudioBufferList* cloneBufferList(AudioBufferList* bufferList);

#define SAMPLE_TYPE_UNKNOW         -1
#define SAMPLE_TYPE_INT16          0
#define SAMPLE_TYPE_INT32          1
#define SAMPLE_TYPE_flOAT          2
int getAudioFormatType(AudioStreamBasicDescription audioFormat);


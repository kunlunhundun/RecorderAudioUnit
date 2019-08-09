//
//  EAudioGraph.h
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "EAudioNode.h"
#import "EAudioSpot.h"

typedef BOOL (^mixProcessBlock)(int process) ;
typedef BOOL (^renderCallbackBlock)(int frameCount,AudioBufferList* bufferList) ;

typedef NS_ENUM(NSInteger, EAGraphRenderType) {
    EAGraphRenderType_None,
    EAGraphRenderType_RealTime, //输出到remote ioNode ///
    EAGraphRenderType_Offline   //输出到GenericOutput Node
};

@interface EAudioGraph : NSObject

@property (nonatomic,assign) EAGraphRenderType graphRenderType;
;
@property (nonatomic,assign,readonly) AUGraph graph;
@property (nonatomic,strong,readonly) NSString* name;
@property (nonatomic,assign)          BOOL    pause;
@property (nonatomic,assign)          float   volume;
@property (nonatomic,assign)          float   reverbValue;
@property (nonatomic,assign)          int     eqType;
@property (nonatomic, assign)         NSTimeInterval currentTime;
@property (nonatomic, assign)         BOOL isSkip;

@property (nonatomic, assign)         NSTimeInterval baseOffset;  //当移动人声为正数时，需要移动伴奏
@property (nonatomic,assign)          NSTimeInterval captureOffset;  //短音频时，截取时间的偏移

@property (nonatomic,readonly)        AudioStreamBasicDescription defaultStreamFormat;
@property (nonatomic,copy)            renderCallbackBlock renderCB; //pcm數據囘調

-(instancetype)initWithName:(NSString*)name withType:(EAGraphRenderType)type;

-(instancetype)initWithName:(NSString*)name SampleRate:(float)sampleRate withType:(EAGraphRenderType)type;

-(void)startGraph;

-(void)stopGraph;

-(EAudioSpot*)createAudioSpot:(NSString*)audioFile withName:(NSString*)spotName;

-(EAudioSpot*)createMicAudioSpot:(NSString*)spotName;

-(void)addAudioSpot:(EAudioSpot*)spot;

-(void)removeAudioSpot:(EAudioSpot*)spot;

-(BOOL)startRecord:(NSString*)savePath;

-(void)stopRecord;

-(void)startOfflineRender:(NSString*)savePath
          TotalFrameCount:(UInt64)frameCount
             ProcessBlock:(mixProcessBlock)block;

-(void)startOfflineRender:(UInt64)frameCount
             renderBlock:(renderCallbackBlock)block;


-(EAudioNode*)createAudioNode:(OSType)nodeComponentType
             componentSubType:(OSType)nodeComponentSubType
                 withNodeName:(NSString*)nodeName;

-(void)removeAudioNode:(EAudioNode*)node;

-(BOOL)connectAudioNode:(EAudioNode*)fromNode
             FromBusNum:(int)fromBusNum
                 ToNode:(EAudioNode*)toNode
               ToBusNum:(int)toBusNum;
-(BOOL)disconnectAudioNode:(EAudioNode*)destNode destInputBusNum:(int)busNum;


- (void)setVolume:(float)volume AudioSpot:(EAudioSpot*)spot;
-(float)getVolume:(EAudioSpot*)spot;
@end

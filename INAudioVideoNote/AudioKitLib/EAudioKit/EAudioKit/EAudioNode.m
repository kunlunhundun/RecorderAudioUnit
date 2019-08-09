//
//  EAudioNode.m
//  AudioTest
//
//  Created by cybercall on 15/7/10.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import "EAudioNode.h"
#import "EAInteranl.h"
#import "EAMicro.h"
#import "EAudioMisc.h"

@implementation EAudioNode

-(instancetype)initWithNode:(AUGraph)graph withNode:(AUNode)node withName:(NSString*)name
{
    self = [super init];
    _audioNode = node;
    _audioName = name;
    _graph = graph;
    OSStatus err = AUGraphNodeInfo(_graph, _audioNode, NULL, &_audioUnit);
    CHECK_ERROR(err,"AUGraphNodeInfo failed");
    
    MARK_INSTANCE();
    return self;
}

-(void)dealloc
{
    UNMARK_INSTANCE();
    CHECK_ERROR(-1,"EAudioNode dealloc\n");
    
}

//-(BOOL)setInputFormat:(int)busNum Format:(const AudioStreamBasicDescription)foramt
-(BOOL)setInputFormat:(int)busNum Format:( AudioStreamBasicDescription )foramt
{
    AudioStreamBasicDescription oldFormat;
    [self getInputFormat:busNum Format:&oldFormat];
    OSStatus err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, busNum, &foramt, sizeof(foramt));
    CHECK_ERROR(err,"setInputFormat failed");
    if (err != noErr) {
        NSLog(@"node:%@,set input format(busNum:%d):\n %@---------------------->>>>\n%@ fail!!!!\n",
              _audioName,busNum,
              [AudioStreamBasicDescriptions formatASBD:oldFormat],
              [AudioStreamBasicDescriptions formatASBD:foramt]);
    }
    return (err == noErr);
}

-(BOOL)setOutputFormat:(int)busNum Format:(AudioStreamBasicDescription)foramt
{
    AudioStreamBasicDescription oldFormat;
    [self getOutputFormat:busNum Format:&oldFormat];
    OSStatus err = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, busNum, &foramt, sizeof(foramt));
    CHECK_ERROR(err,"setOutputFormat failed");
    
    if (err != noErr) {
        NSLog(@"node:%@,set output format(busNum:%d):\n %@--------------------->>>>\n%@ fail!!!!\n",
              _audioName,busNum,
              [AudioStreamBasicDescriptions formatASBD:oldFormat],
              [AudioStreamBasicDescriptions formatASBD:foramt]);
    }
    return (err == noErr);
}

-(BOOL)getInputFormat:(int)busNum Format:(AudioStreamBasicDescription*)format
{
    memset(format, 0, sizeof(*format));
    UInt32 size = sizeof(*format);
    OSStatus err = AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, busNum, format, &size);
    CHECK_ERROR(err,"getInputFormat failed");
    return (err == noErr);
}

-(BOOL)getOutputFormat:(int)busNum Format:(AudioStreamBasicDescription*)format
{
    memset(format, 0, sizeof(*format));
    UInt32 size = sizeof(*format);
    OSStatus err = AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, busNum, format, &size);
    CHECK_ERROR(err,"getOutputFormat failed");
    return (err == noErr);
}
-(void)onNodeConnected:(EAudioNode*)target isConnectToTargetOutput:(BOOL)isConnectToTargetOutput
{
    
}

@end

//
//  AudioRecord.h
//  EAudioKit
//
//  Created by zhou on 16/3/23.
//  Copyright © 2016年 rcsing. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^finish)(); // 结束录音事件
typedef void(^audioPowerEvent)(float power); // 录音声波事件

@interface AudioRecord : NSObject

+ (AudioRecord *)shareInstance;
- (void)startRecordWithSavePath:(NSString *)savePath andPowerEvent:(audioPowerEvent)powerEvent;
- (void)stopRecordWhenFinish:(finish)finishAction;

@end

//
//  RecordManager.h
//  EAudioKit
//
//  Created by zhou on 15/10/26.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef void (^recorderCompleteBlock)();

@interface RecordManager : NSObject
@property (assign,nonatomic,readonly) BOOL isRecording;
@property (assign,nonatomic) BOOL enableBilateralFitler;

+ (RecordManager *)sharedManager;

- (void)beginPreview;
- (void)stopPreview;

- (BOOL)beginRecordWithSave:(NSString *)path;
- (void)endRecording;

- (void)changeCamera;
- (UIView *)getPreView;

- (void)setFoucusWithPoint:(CGPoint)point;
- (void)setFlashMode:(AVCaptureFlashMode)flashMode;
- (void)setFocusMode:(AVCaptureFocusMode)focusMode;
- (void)setExposureMode:(AVCaptureExposureMode)exposureMode;
- (void)rotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

- (void)setFilterType:(int)index;

/*- (void)beginPreviewWithVideoResources:(NSString *)videoUrl;*/

- (void)setBilateralParam:(float)effect withSampleRadius:(float)radius;

@end

//
//  RecordManager.m
//  EAudioKit
//
//  Created by zhou on 15/10/26.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "RecordManager.h"
#include <VideoToolbox/VideoToolbox.h>
#import "EAudioKit/CoreImageView.h"
#import "EAudioMisc.h"
#import "BilateralFilter.h"

#define RECORDE_IDLE            0
#define RECORDE_WRITING         1
#define RECORDE_PREPARE_EXIT    2

#define IMAGE_SIZE              480

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface RecordManager() < AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong,nonatomic) AVCaptureVideoPreviewLayer * captureVideoPreviewLayer;// 相机拍摄预览图层
@property (strong,nonatomic) AVCaptureSession * captureSession;// 负责输入和输出设置之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput * captureDeviceInput;// 负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (strong,nonatomic) AVCaptureVideoDataOutput * captureVideoDataOutput;// 输出
@property (copy  ,nonatomic) NSString * path;
@property (copy  ,nonatomic) recorderCompleteBlock completeBlock;
@property (assign,nonatomic) BOOL isFontCamera;

@property (strong,nonatomic) AVAssetWriter * assetWriter;
@property (assign,nonatomic) CMTime currentSampleTime;
@property (strong,nonatomic) AVAssetWriterInputPixelBufferAdaptor * assetWriterPixelBufferInputAdaptor;
@property (strong,nonatomic) CIContext * coreImageContext;
@property (strong,nonatomic) CIFilter * filter;
@property (strong,nonatomic) CoreImageView * preView;
@property (assign,nonatomic) int recordState;

@property (strong,nonatomic) AVPlayer * player;
@property (strong,nonatomic) AVPlayerItemVideoOutput * videoOutput;
@property (strong,nonatomic) CIImage * videoImage;

@property (strong,nonatomic) BilateralFilter* bilateralFilter;
@end

@implementation RecordManager

+ (RecordManager *)sharedManager {
    static RecordManager * mannager = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        mannager = [[self alloc] init];
        [mannager configCaptureSession];
    });
    return mannager;
}

- (void)configCaptureSession {
    if (_captureSession) {return;}
    
    _videoDataOutputQueue = dispatch_queue_create("video_queue", DISPATCH_QUEUE_SERIAL );
    dispatch_set_target_queue(_videoDataOutputQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ));
    dispatch_async(_videoDataOutputQueue, ^{
        [self initImageContext];
    });
    
    _captureSession=[[AVCaptureSession alloc]init];
    [_captureSession beginConfiguration];
    
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) { // 设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }
    _captureSession.usesApplicationAudioSession = NO;
    
    // 获得输入设备
    AVCaptureDevice * captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];//取得摄像头
    if (!captureDevice) {
        DEBUG_LOG(@"取得后置摄像头时出现问题.");
        return ;
    }
    _isFontCamera = YES;
    
    NSError *error2;
    [captureDevice lockForConfiguration:&error2];
    if (error2 == nil) {
        if (captureDevice.activeFormat.videoSupportedFrameRateRanges){
            [captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 15)];
            [captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 15)];
        }
    }else{
        // handle error2
    }
    [captureDevice unlockForConfiguration];
    
    NSError * error = nil;
    // 根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        DEBUG_LOG(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return ;
    }
    if([_captureSession canAddInput:_captureDeviceInput]){
        //视频输入设备
        [_captureSession addInput:_captureDeviceInput];
    }
    
    [self connectVideoDataOutput];
    [self setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    
    [_captureSession commitConfiguration];
    _recordState = RECORDE_IDLE;
}

-(BOOL)isRecording {
    return (_recordState != RECORDE_IDLE);
}

-(void)setEnableBilateralFitler:(BOOL)enable
{
    _enableBilateralFitler = enable;
}

/**
 *  设置视频数据输出
 */
- (void)connectVideoDataOutput {
    _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // 数据格式设置 同步调整 createWriter 方法中的设置
    _captureVideoDataOutput.videoSettings = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}; // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange kCVPixelFormatType_32BGRA
    _captureVideoDataOutput.alwaysDiscardsLateVideoFrames=YES;
    
    [_captureVideoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureVideoDataOutput]) {
        [_captureSession addOutput:_captureVideoDataOutput];
    }
}

- (void)beginPreview {
    
    if (_enableBilateralFitler) {
        _bilateralFilter = [[BilateralFilter alloc] init];
    }
    
    AVCaptureConnection * captureConnection = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if ([captureConnection isVideoStabilizationSupported]) {
        // 自动防抖
        if([captureConnection respondsToSelector:@selector(setPreferredVideoStabilizationMode:)]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    // 设置每秒的帧数 默认30帧
    //captureConnection.videoMaxFrameDuration = CMTimeMake(1, 15);
    //captureConnection.videoMinFrameDuration = CMTimeMake(1, 15);
    
    [_captureSession startRunning];
    
    
#if false
    [self configVideoBufferWithUrl:[[NSBundle mainBundle] pathForResource:@"Cat.mp4" ofType:nil]];
#endif
}

- (void)stopPreview {
    [_captureSession stopRunning];
    
    [_player pause];
    
    _bilateralFilter = nil;
}

- (void)initImageContext {
    if (_coreImageContext == nil) {
        EAGLContext * context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSDictionary * opt = @{kCIContextWorkingColorSpace: [NSNull null]};
        _coreImageContext = [CIContext contextWithEAGLContext:context options:opt];
    }
}

/*磨皮效果*/
- (void)setBilateralParam:(float)effect withSampleRadius:(float)radius
{
    if (_bilateralFilter == nil) {
        return;
    }
    
    _bilateralFilter.bilateralRadius = radius;
    _bilateralFilter.bilateralEffect = effect;
}

/**
 *  视频编码设置
 */
- (NSDictionary *)getVideoOutputSettings {
    NSDictionary * compressionSetting = @{
                                          AVVideoAverageBitRateKey: @(IMAGE_SIZE*IMAGE_SIZE*4),
                                          AVVideoExpectedSourceFrameRateKey : @(30),
                                          AVVideoMaxKeyFrameIntervalKey : @(60), // 关键帧最大间隔 1为每个都是关键帧
                                          AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline30,
                                          AVVideoAllowFrameReorderingKey: @NO
                                          };
    
    NSDictionary * outputSettings = @{
                                      AVVideoCodecKey: AVVideoCodecH264,
                                      AVVideoWidthKey: @(IMAGE_SIZE),
                                      AVVideoHeightKey: @(IMAGE_SIZE),
                                      AVVideoCompressionPropertiesKey:compressionSetting,
                                      };
    
    return outputSettings;
}

/**
 *  创建 AVAssetWriter
 */
- (void)createWriter {
    NSURL * url = [NSURL fileURLWithPath:_path];
    NSString * fileType = AVFileTypeMPEG4;
    if ([_path hasSuffix:@"mov"]) {
        fileType = AVFileTypeQuickTimeMovie;
    } else if ([_path hasSuffix:@"m4v"]) {
        fileType = AVFileTypeAppleM4V;
    }
    _assetWriter = [[AVAssetWriter alloc]initWithURL:url fileType:fileType error:nil];
    NSDictionary * outputSettings = [self getVideoOutputSettings];
    
    AVAssetWriterInput * assetWriterVideoInput = [[AVAssetWriterInput alloc]initWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary * sourcePixelBufferAttributes = @{
                                                   (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
                                                   (__bridge NSString *)kCVPixelFormatOpenGLESCompatibility: @(YES)
                                                   };
    
    _assetWriterPixelBufferInputAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc]initWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    
    if ([_assetWriter canAddInput:assetWriterVideoInput]) {
        [_assetWriter addInput:assetWriterVideoInput];
    }
}

- (BOOL)beginRecordWithSave:(NSString *)path {
    if (_recordState != RECORDE_IDLE){
        DEBUG_LOG(@"beginRecordWithSave error!!!");
        return NO;
    }
    
    _path = path;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]){
        if ([fileManager removeItemAtPath:path error:nil] == NO){
            return NO;
        }
    }
    @synchronized(self) {
        _recordState = RECORDE_WRITING;
        dispatch_async(_videoDataOutputQueue, ^{
            [self createWriter];
        });
    }
    
    return YES;
}

- (void)endRecording {
    static BOOL g_isRunning = NO;
    if (g_isRunning){return;}
    
    CFRunLoopRef loopRef = CFRunLoopGetCurrent();
    BOOL bShouldWait = [self endRecording:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            CFRunLoopStop(loopRef);
        });
    }];
    
    if (bShouldWait) {
        g_isRunning = YES;
        CFRunLoopRun();//等待視頻保存完畢
        g_isRunning = NO;
    }
}

- (BOOL)endRecording:(recorderCompleteBlock)complete {
    
    [_player pause];
    
    if (_recordState != RECORDE_WRITING) {
        return NO;
    }
    
    _recordState = RECORDE_PREPARE_EXIT;
    
    [_captureSession stopRunning];
    
    [self removeNotification];
    
    if (_assetWriter.status == AVAssetWriterStatusWriting) {
        _completeBlock = complete;
        
        @synchronized(self){
            dispatch_async(_videoDataOutputQueue, ^{
                [_assetWriter finishWritingWithCompletionHandler:^{
                    _assetWriterPixelBufferInputAdaptor = nil;
                    _assetWriter = nil;
#if DEBUG
                    NSFileManager* fileMgr = [NSFileManager defaultManager];
                    NSDictionary<NSString *, id>* dict = [fileMgr attributesOfItemAtPath:_path error:NULL];
                    if(dict != nil){
                        float size = [dict fileSize] / 1024.0;
                        if(size > 1024 ){
                            DEBUG_LOG(@"captureOutput end,%@,size:%.2fMb",_path,size/1024);
                        }else{
                            DEBUG_LOG(@"captureOutput end,%@,size:%.2fKb",_path,size);
                        }
                    }
#endif
                    
                    if (self.completeBlock != nil) {
                        self.completeBlock();
                        self.completeBlock = nil;
                    }
                    
                    _recordState = RECORDE_IDLE;
                    
                }];
            });
        }
        return YES;
    }else{
        DEBUG_LOG(@"ERROR,endRecording->status:%ld",(long)_assetWriter.status);
        _recordState = RECORDE_IDLE;
        return NO;
    }
}

#pragma mark - 滤镜

- (void)setFilterType:(int)index {
    if (index >= [self filtersName].count) {
        return;
    }
    
    _filter = [CIFilter filterWithName:[self filtersName][index]];
    
}

/**
 *  @return 滤镜类型数组
 *  https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP30000136-SW29
 */
- (NSArray *)filtersName {
    return @[
             // @"CIColorInvert", // 反色
             // @"CIPhotoEffectMono", // 单色
             @"CIPhotoEffectChrome",
             @"CIPhotoEffectInstant", // 自然
             @"CIPhotoEffectTransfer", // 怀旧
             @"CISepiaTone", // 老照片
             ];
}

- (CIFilter *)filter {
    if (_filter == nil) {
        _filter = [CIFilter filterWithName:[self filtersName][0]];
        
        // [self printAllFilters];
    }
    return _filter;
}

/**
 *  输出所有滤镜及参数
 */
- (void)printAllFilters {
    NSArray * filterNames = [CIFilter filterNamesInCategory:kCICategoryBuiltIn];
    
    for (NSString * filterName in filterNames) {
        CIFilter * filter = [CIFilter filterWithName:filterName];
        NSLog(@"%@", [filter attributes]);
    }
}


#pragma mark - 视频逐帧处理得到数据
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    @synchronized(self) {
        _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage * sourceImage = [[CIImage alloc]initWithCVPixelBuffer:imageBuffer];
        
        if (_bilateralFilter != nil) {
            //先进行磨皮
            [_bilateralFilter setValue:sourceImage forKey:kCIInputImageKey];
            CIImage* bilateralImage = _bilateralFilter.outputImage;
            if (bilateralImage != nil)
            {
                sourceImage = bilateralImage;
            }
        }
        [self.filter setValue:sourceImage forKey:kCIInputImageKey];
        
        CGAffineTransform transForm;
        if (_isFontCamera) { // 前置摄像头
            transForm = CGAffineTransformMakeScale(-1, 1); // 先左右对调
            transForm = CGAffineTransformRotate(transForm, -M_PI_2); // 再旋转90度
        } else {
            transForm = CGAffineTransformMakeRotation(-M_PI_2);
        }
        
        CIImage * preImage = [_filter.outputImage imageByApplyingTransform:transForm];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_preView updateImage:preImage];
        });
        
#if false
        CVPixelBufferRef newPixelBuffer = NULL;
        CVPixelBufferPoolCreatePixelBuffer(nil, _assetWriterPixelBufferInputAdaptor.pixelBufferPool, &newPixelBuffer);
        
        // 平移图像  顶端对齐 只要上面的480像素数据
        CGAffineTransform transForm;
        if (_isFontCamera) { // 前置摄像头
            transForm = CGAffineTransformMakeTranslation(IMAGE_SIZE, IMAGE_SIZE);
        } else {
            transForm = CGAffineTransformMakeTranslation(0, IMAGE_SIZE);
        }
        
        CIImage * transFromImage = [preImage imageByApplyingTransform:transForm];
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
            [_coreImageContext render:transFromImage toCVPixelBuffer:newPixelBuffer bounds:CGRectMake(IMAGE_SIZE * 0.5, 0, IMAGE_SIZE * 0.5, IMAGE_SIZE) colorSpace:nil];
        } else {
            [_coreImageContext render:transFromImage toCVPixelBuffer:newPixelBuffer bounds:CGRectMake(0, 0, IMAGE_SIZE, IMAGE_SIZE) colorSpace:nil];
        }
        
        CIImage * videoImage = [self getVideoCIImage];
        if (videoImage) {
            _videoImage = videoImage;
        }
        [_coreImageContext render:_videoImage toCVPixelBuffer:newPixelBuffer bounds:CGRectMake(0, 0, IMAGE_SIZE * 0.5, IMAGE_SIZE) colorSpace:nil];
        
        CIImage * newImage = [[CIImage alloc]initWithCVPixelBuffer:newPixelBuffer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_preView updateImage:newImage];
        });
#endif
        
        CVPixelBufferRef newPixelBuffer = NULL;
        if (_recordState == RECORDE_WRITING) {
            if (_assetWriter.status != AVAssetWriterStatusWriting ) {
                [_assetWriter startWriting];
                [_assetWriter startSessionAtSourceTime:_currentSampleTime];
            }
            
            if (_assetWriterPixelBufferInputAdaptor.assetWriterInput.readyForMoreMediaData) {
                
                // 平移图像  顶端对齐 只要上面的480像素数据
                CGAffineTransform transForm;
                if (_isFontCamera) { // 前置摄像头
                    transForm = CGAffineTransformMakeTranslation(IMAGE_SIZE, IMAGE_SIZE);
                } else {
                    transForm = CGAffineTransformMakeTranslation(0, IMAGE_SIZE);
                }
                CIImage * transFromImage = [preImage imageByApplyingTransform:transForm];
                
                CVPixelBufferPoolCreatePixelBuffer(nil, _assetWriterPixelBufferInputAdaptor.pixelBufferPool, &newPixelBuffer);
                
                [_coreImageContext render:transFromImage toCVPixelBuffer:newPixelBuffer];
                
                BOOL b = [_assetWriterPixelBufferInputAdaptor appendPixelBuffer:newPixelBuffer withPresentationTime:_currentSampleTime];
                if (b == NO) {
                    DEBUG_LOG(@"fail to appendPixelBuffer");
                }
            }
        }
        CVPixelBufferRelease(newPixelBuffer);
    }
}

#pragma mark - 从视频获取帧数据
- (void)configVideoBufferWithUrl:(NSString *)videoUrl {
    
    _player = [[AVPlayer alloc]initWithURL:[NSURL fileURLWithPath:videoUrl]];
    
    NSDictionary * pixelBufferDict = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    _videoOutput = [[AVPlayerItemVideoOutput alloc]initWithPixelBufferAttributes:pixelBufferDict];
    [_player.currentItem addOutput:_videoOutput];
    
    [_player play];
}

- (CIImage *)getVideoCIImage {
    
    CMTime itemTime = _player.currentTime;
    
    if ([_videoOutput hasNewPixelBufferForItemTime:itemTime]) {
        CMTime presentationItemTime = kCMTimeZero;
        CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:&presentationItemTime];
        
        CIImage * image = [[CIImage alloc]initWithCVPixelBuffer:pixelBuffer];
        
        CVPixelBufferRelease(pixelBuffer);
        
        return image;
    }
    
    return nil;
}


#pragma mark - 视频预览View
- (UIView *)getPreView {
    if (!_preView) {
        _preView = [[CoreImageView alloc]initWithFrame:CGRectZero];
        _preView.backgroundColor = [UIColor blackColor];
    }
    
    return _preView;
}

#pragma mark - 取得指定位置的摄像头
/**
 *  AVCaptureDevicePositionBack  AVCaptureDevicePositionFront
 *  @return 摄像头设备
 */
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position{
    NSArray * cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}


#pragma mark - 切换摄像头、聚焦、闪光灯模式、聚焦模式、曝光模式
/**
 *  切换摄像头
 */
- (void)changeCamera {
    AVCaptureDevice * currentDevice = [_captureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    
    AVCaptureDevice * toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    _isFontCamera = YES;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
        _isFontCamera = NO;
    }
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    
    // 获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    // 改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [_captureSession beginConfiguration];
    // 移除原有输入对象
    [_captureSession removeInput:_captureDeviceInput];
    // 添加新的输入对象
    if ([_captureSession canAddInput:toChangeDeviceInput]) {
        [_captureSession addInput:toChangeDeviceInput];
        _captureDeviceInput = toChangeDeviceInput;
    }
    // 提交会话配置
    [_captureSession commitConfiguration];
}

/*
 *  设置聚焦点
 */
- (void)setFoucusWithPoint:(CGPoint)point{
    CGPoint cameraPoint= [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

/**
 *  设置闪光灯模式
 */
-(void)setFlashMode:(AVCaptureFlashMode)flashMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFlashModeSupported:flashMode]) {
            [captureDevice setFlashMode:flashMode];
        }
    }];
}

/**
 *  设置聚焦模式
 */
-(void)setFocusMode:(AVCaptureFocusMode)focusMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

/**
 *  设置曝光模式
 */
-(void)setExposureMode:(AVCaptureExposureMode)exposureMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
    }];
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

- (void)rotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    [_captureVideoPreviewLayer connection].videoOrientation=(AVCaptureVideoOrientation)toInterfaceOrientation;
}

/**
 *  改变设备属性的操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice * captureDevice = [_captureDeviceInput device];
    NSError * error;
    // 改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

#pragma mark - 通知
/**
 *  移除所有通知
 */
-(void)removeNotification{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

/**
 *  设备连接成功
 */
-(void)deviceConnected:(NSNotification *)notification {
    NSLog(@"deviceConnected...");
}
/**
 *  设备连接断开
 */
-(void)deviceDisconnected:(NSNotification *)notification {
    NSLog(@"deviceDisconnected...");
}

/**
 *  会话出错
 */
-(void)sessionRuntimeError:(NSNotification *)notification{
    NSLog(@"sessionError...");
}

@end

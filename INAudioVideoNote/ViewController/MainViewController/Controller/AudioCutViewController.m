//
//  AudioCutViewController.m
//  INAudioVideoNote
//
//  Created by kunlun on 06/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "AudioCutViewController.h"
#import <EZAudioIOS/EZAudio.h>
#import <Masonry/Masonry.h>
#import "INConst.h"
#import "CustomImgLabBtn.h"
#import <EAudioKit/EAudioKit.h>
#import "FilePathManager.h"
#import "DoubleSliderView.h"
#import "UIView+Extension.h"
#import "AudioInfoModel.h"



@interface AudioCutViewController ()

@property (nonatomic, strong)  EZAudioPlotGL *audioPlotGLView;
@property(nonatomic,strong) EAudioGraph *audioGraph;
@property(nonatomic,strong) EAudioSpot *audioSpot;
@property(nonatomic,assign) BOOL isPause;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) int timeCount;
@property(nonatomic,strong)  UILabel *timerLabel;
@property(nonatomic,strong)  UILabel *leftTimeLab;
@property(nonatomic,strong)  UILabel *rightTimeLab;
@property(nonatomic,strong)  UIButton *playBtn;
@property(nonatomic,assign) NSTimeInterval durationCount;

@property(nonatomic,assign) NSTimeInterval startTime;
@property(nonatomic,assign) NSTimeInterval endTime;

@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;
@property(nonatomic,strong) EAudioFileRecorder *readFileRecorder;

@end

@implementation AudioCutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self initNavigation];
    [self initView];
    [self initAudio];
    
}

-(void)initNavigation{
    UIButton * btn = [[UIButton alloc]initWithFrame:CGRectZero];
    btn.frame = CGRectMake(0, 0, 60,44);
    UIImageView *backImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, (44-24)/2.0, 28, 24)];
    [btn addSubview:backImgView];
    backImgView.contentMode = UIViewContentModeScaleAspectFit;
    backImgView.image = [UIImage imageNamed:@"arow_back"];
    [btn addTarget:self action:@selector(goBackAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * backBarBtn = [[UIBarButtonItem alloc]initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = backBarBtn ;
}

-(void)initAudioPlotGL{
    _audioPlotGLView = [[EZAudioPlotGL alloc]initWithFrame:CGRectZero];
    [self.view addSubview:_audioPlotGLView];
    [_audioPlotGLView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(0);
        make.height.mas_equalTo(220);
    }];
    _audioPlotGLView.backgroundColor = UIColorFromRGB(0x151515);
    _audioPlotGLView.color           =  UIColorFromRGB(0xFF5700);
    _audioPlotGLView.plotType        = EZPlotTypeRolling;
    _audioPlotGLView.shouldFill      = YES;
    _audioPlotGLView.shouldMirror    = YES;
    _audioPlotGLView.gain = 2.5f;
    
    float *outFloatData;
    outFloatData =  (float*)calloc(8, sizeof(char));
    memset(outFloatData, 0, sizeof(char)*8);
    outFloatData[0] = 0.01;
    outFloatData[1] = 0.01;

    NSTimeInterval durationCount =  [FilePathManager getAudiodurationTimer:_fileName];
    self.durationCount = durationCount;
    self.startTime = 0;
    self.endTime = durationCount;
   
    int count = 44100*durationCount/1024;
    if (count > 2048) {
      //  count = 8192;
        count = 2048;
    }
    
    __weak typeof (self) weakSelf = self;
    EAudioFileRecorder *readFileRecorder = [[EAudioFileRecorder alloc] init];
    _readFileRecorder = readFileRecorder;
    
    _readFileRecorder.eaudioReadFileOutputBlock = ^(float * _Nonnull data, UInt32 numFrames) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.audioPlotGLView updateBuffer:data withBufferRMSSize:numFrames];
        });
    };
    [_audioPlotGLView setRollingHistoryLength:count+2];

    NSString *filePath = [FilePathManager  getAudioFileRecordPath];
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",filePath,_fileName];
    [readFileRecorder openExAudioFile:filePathName bufferSize:count];
    
 
}



-(void)updateBuffer:(float*)outFloatData index:(NSInteger)index{
    
    outFloatData[0] = 0.005;
    outFloatData[1] = 0.005;
    if ((index / 44) >= 2 && (index /44) < 4) {
        outFloatData[1] = 0.015;
        outFloatData[0] = 0.015;
    }
    if ((index / 44) >= 5 && (index /44) < 9) {
        outFloatData[1] = 0.020;
        outFloatData[0] = 0.020;
    }
    if ((index / 44) >= 10 && (index /44) < 11) {
        outFloatData[1] = 0.025;
        outFloatData[0] = 0.020;
    }
    
    
    
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [weakSelf.audioPlotGLView updateBuffer:outFloatData
                                withBufferSize:2];
        NSInteger row = index + 1;
        if (index < 512) {
            [weakSelf updateBuffer:outFloatData index:row];
        }
        
    });
    
}
-(void)setupSliderView{
    
    UIView *maskView = [[UIView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:maskView];
    [maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self.view);
        make.height.mas_equalTo(260);
    }];
    UIView *leftLineView = [[UIView alloc]initWithFrame:CGRectZero];
    [maskView addSubview:leftLineView];
    leftLineView.backgroundColor = UIColorFromRGB(0xFF5700);
    [leftLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(maskView).offset(14);
        make.top.equalTo(maskView);
        make.height.mas_equalTo(220);
        make.width.mas_equalTo(1);
    }];
    
    UIView *rightLineView = [[UIView alloc]initWithFrame:CGRectZero];
    [maskView addSubview:rightLineView];
    rightLineView.backgroundColor = UIColorFromRGB(0xFF5700);
    [rightLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(maskView).offset(-14);
        make.top.equalTo(maskView);
        make.height.mas_equalTo(220);
        make.width.mas_equalTo(1);
    }];
    
    DoubleSliderView *sliderView = [[DoubleSliderView alloc]initWithFrame:CGRectMake(0, 0, IN_IPHONE_WIDTH, 28)];
    [maskView addSubview:sliderView];
    [sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.audioPlotGLView.mas_bottom);
        make.height.mas_equalTo(28);
    }];
    __weak typeof (self) weakSelf = self;
    sliderView.sliderBtnChangePointBlock = ^(CGPoint leftPoint, CGPoint rightPoint) {
        
        leftLineView.centerX = leftPoint.x;
        rightLineView.centerX = rightPoint.x;
        
        int startTime =  weakSelf.durationCount *  (leftPoint.x - 14) / IN_IPHONE_WIDTH;
        int endTime =  weakSelf.durationCount *  (rightPoint.x + 14) / IN_IPHONE_WIDTH;
        weakSelf.startTime = startTime;
        weakSelf.timeCount = startTime;
        weakSelf.endTime = endTime;
        [weakSelf formatterTime:startTime timeLab:weakSelf.leftTimeLab];
        [weakSelf formatterTime:endTime timeLab:weakSelf.rightTimeLab];

        
    };
   
    
}

-(void)initView{
    
    self.title = @"裁剪录音";
    self.isPause = true;
    self.view.backgroundColor = UIColorFromRGB(0x2E2D38);
    self.startTime = 0;
    self.timeCount = 0;

    [self initAudioPlotGL];
    [self setupSliderView];
    
    self.activityIndicator.frame= CGRectZero;
    //设置小菊花颜色
    self.activityIndicator.color = [UIColor whiteColor];
    //设置背景颜色
    self.activityIndicator.backgroundColor = [UIColor cyanColor];
    //刚进入这个界面会显示控件，并且停止旋转也会显示，只是没有在转动而已，没有设置或者设置为YES的时候，刚进入页面不会显示
    self.activityIndicator.hidesWhenStopped = true;
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
        make.width.height.mas_equalTo(50);
    }];
    
    UILabel *leftTimeLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.view addSubview:leftTimeLab];
    _leftTimeLab = leftTimeLab;
    leftTimeLab.text = @"00:00:00";
    leftTimeLab.textColor = [UIColor whiteColor];
    leftTimeLab.font = [UIFont systemFontOfSize:14];
    [leftTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(15);
        make.top.equalTo(self.audioPlotGLView.mas_bottom).offset(40);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(20);
    }];

    UILabel *rightTimeLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.view addSubview:rightTimeLab];
    _rightTimeLab = rightTimeLab;
    rightTimeLab.text = @"00:00:00";
    rightTimeLab.textColor = [UIColor whiteColor];
    rightTimeLab.font = [UIFont systemFontOfSize:14];
    [rightTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-15);
        make.top.equalTo(leftTimeLab.mas_top);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(20);
    }];
    [self formatterTime:self.durationCount timeLab:self.rightTimeLab];


    UILabel *timerLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.view addSubview:timerLab];
    _timerLabel = timerLab;
    timerLab.textColor = [UIColor whiteColor];
    timerLab.text = @"00:00:00";
    timerLab.textAlignment = NSTextAlignmentCenter;
    timerLab.font = [UIFont fontWithName:@"DINAlternate-Bold" size:36];
    [timerLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.audioPlotGLView.mas_bottom).offset(80);
        make.height.mas_equalTo(42);
    }];
    
    UIButton *playBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    [playBtn setImage:[UIImage imageNamed:@"in_button_stop"] forState:UIControlStateNormal];
    [playBtn setImage:[UIImage imageNamed:@"in_button_play"] forState:UIControlStateSelected];
    [self.view addSubview:playBtn];
    [playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(timerLab.mas_bottom).offset(40);
        make.width.height.mas_equalTo(68);
    }];
    _playBtn = playBtn;
    [playBtn addTarget:self action:@selector(playStartAction:) forControlEvents:UIControlEventTouchUpInside];
    
    CustomImgLabBtn *saveCustomBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 74, 38)];
    [self.view addSubview:saveCustomBtn];
    saveCustomBtn.backgroundColor = UIColorFromRGB(0x3B3B4D);
    saveCustomBtn.layer.cornerRadius = 19;
    saveCustomBtn.clipsToBounds = true;
    [saveCustomBtn setTitle:@"完成" forState:UIControlStateNormal];
    [saveCustomBtn setImage:[UIImage imageNamed:@"in_icon_finish"] forState:UIControlStateNormal];
    [saveCustomBtn addTarget:self action:@selector(finishCutAction) forControlEvents:UIControlEventTouchUpInside];
    [saveCustomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(playBtn.mas_right).offset(35);
        make.centerY.equalTo(playBtn.mas_centerY);
        make.width.mas_equalTo(74);
        make.height.mas_equalTo(38);
    }];
}

-(void)initAudio{
    NSString *filePath = [FilePathManager  getAudioFileRecordPath];
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",filePath,_fileName];
    _audioGraph = [[EAudioGraph alloc] initWithName:@"playAudioGraph" withType:EAGraphRenderType_RealTime];
    EAudioSpot *audioSpot =  [_audioGraph createAudioSpot:filePathName withName:@"playFilePlayer"];
    [_audioGraph addAudioSpot:audioSpot];
    _audioSpot = audioSpot;
    __weak typeof (self) weakSelf = self;
    audioSpot.onPlayDataBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
       
    };
    audioSpot.onPlayEnd = ^(EAudioSpot *spot) {
        [weakSelf pausePlay];
    };
}




-(void)playStartAction:(UIButton*)sendBtn{
   
    if (_isPause) {
        if (self.startTime > 0.1) {
            [_audioGraph setCurrentTime:self.startTime];
        }
        [_audioGraph startGraph];
        _isPause = false;
        sendBtn.selected = true;
        [self startTimer];
    }else{
        [self pausePlay];
    }
}
-(void)pausePlay{
    [_audioGraph stopGraph];
    _isPause = true;
    _playBtn.selected = false;
}

-(void)stopPlay{
    [_audioGraph stopGraph];
    _audioSpot = nil;
    _audioGraph = nil;
    _isPause = true;
    [_audioPlotGLView clear];
    [_audioPlotGLView pauseDrawing];
    [_audioPlotGLView removeFromSuperview];
    _audioPlotGLView = nil;
    [self destoryTimer];
}



-(void)finishCutAction{
    
    __weak typeof(self)  weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"重命名"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    // 2.1 添加文本框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    // 2.2  创建Cancel Login按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *fileNameField = alertController.textFields.firstObject;
        NSString * fileName = fileNameField.text;
        if (fileName.length > 1) {
            [weakSelf cutFileName:fileName];
        }
        NSLog(@"name is %@",fileName);
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:loginAction];
    // 3.显示警报控制器
    [self presentViewController:alertController animated:YES completion:nil];

    
}

-(void)cutFileName:(NSString*)cutName{
    NSString* ext = [self.fileName pathExtension];
    NSString *filePath = [FilePathManager  getAudioFileRecordPath];
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",filePath,self.fileName];
    NSString *outputPathName = [NSString stringWithFormat:@"%@%@.%@",filePath,cutName,ext];
    
    
    [self.activityIndicator startAnimating];
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        BOOL isSuccess =  [EAudioFileRecorder cutFile:filePathName outputFilePath:outputPathName startTime:weakSelf.startTime endTime:weakSelf.endTime durationTime:weakSelf.durationCount];
        if (isSuccess) {
            AudioInfoModel *infoModel = [[AudioInfoModel alloc]init];
            infoModel.fileName = [NSString stringWithFormat:@"%@.%@",cutName,ext];
            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
            formatter.dateFormat = @"yyyy/MM/dd hh:mm:ss";
            NSString *localSaveDate = [formatter stringFromDate: [NSDate date] ];
            infoModel.dateTime = localSaveDate;
            [FilePathManager saveArchiverModel:infoModel];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isSuccess == true) {
                [weakSelf.activityIndicator stopAnimating];
                [self.navigationController popViewControllerAnimated:true];
            }
        });
    });
}


-(void)goBackAction{
    [self stopPlay];
    [self.navigationController popViewControllerAnimated:true];
}


- (void)startTimer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
        [_timer fire];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)destoryTimer {
    if (_timer && [self.timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)timerEvent {
    
    if (_isPause == true) {
        return ;
    }
    self.timeCount += 1;
    [self formatterTime:self.timeCount timeLab:self.timerLabel];
}

-(void)formatterTime:(NSInteger)timeCount timeLab:(UILabel*)timeLab{
    NSInteger minutes = timeCount / 60;
    NSInteger seconds =  timeCount % 60;
    NSInteger hours = minutes / 60;
    minutes = minutes % 60;
    NSString *secondStr = seconds < 10 ? [NSString stringWithFormat:@"0%ld",seconds] : [NSString stringWithFormat:@"%ld",seconds];
    NSString *minuteStr = minutes < 10 ? [NSString stringWithFormat:@"0%ld",minutes] : [NSString stringWithFormat:@"%ld",minutes];
    NSString *hourStr = hours < 10 ? [NSString stringWithFormat:@"0%ld",hours] : [NSString stringWithFormat:@"%ld",hours];
    timeLab.text  = [NSString stringWithFormat:@"%@:%@:%@",hourStr,minuteStr,secondStr];
}


@end


//
//  ContinueRecordViewController.m
//  INAudioVideoNote
//
//  Created by kunlun on 31/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "ContinueRecordViewController.h"
#import <EZAudioIOS/EZAudio.h>
#import <Masonry/Masonry.h>
#import "INConst.h"
#import "CustomImgLabBtn.h"
#import <EAudioKit/EAudioKit.h>
#import "FilePathManager.h"
#import "MarkCollectionView.h"
#import "AudioInfoModel.h"

@interface ContinueRecordViewController ()

@property (nonatomic, strong)  EZAudioPlotGL *audioPlotGLView;

@property(nonatomic,strong) EAudioGraph *audioGraph;
@property(nonatomic,strong) EAudioSpot *micSpot;
@property(nonatomic,assign) BOOL isPause;
@property(nonatomic,assign) BOOL discard;

@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) int timeCount;
@property(nonatomic,strong)  UILabel *timerLabel;
@property(nonatomic,strong) UIButton *microphoneBtn;
@property(nonatomic,strong) NSString *saveRecordName;
@property(nonatomic, strong)UIActivityIndicatorView * activityIndicator;

@property(nonatomic,strong) MarkCollectionView *markCollectionView;
@property(nonatomic,strong) NSMutableSet *markTimeSet;
@property(nonatomic,assign) NSTimeInterval durationTime;

@end

@implementation ContinueRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initNavigation];
    [self initView];
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
}


-(void)initView{
    
    self.title = @"继绪录音" ;
    self.isPause = true;
    self.view.backgroundColor = UIColorFromRGB(0x2E2D38);
    self.markTimeSet = [NSMutableSet setWithCapacity:1];
    [self.view addSubview:self.activityIndicator];
   
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
    
    [self initAudioPlotGL];
    
    _durationTime =  [FilePathManager getAudiodurationTimer:_fileName];

    MarkCollectionView *markCollectionView = [[MarkCollectionView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:markCollectionView];
    markCollectionView.backgroundColor = UIColorFromRGB(0x1A1A1C);
    [markCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.audioPlotGLView.mas_bottom).offset(0);
        make.height.mas_equalTo(40);
    }];
    _markCollectionView = markCollectionView;
    markCollectionView.ishowCloseImg = true;
    __weak typeof (self) weakSelf = self;
    markCollectionView.markTimeSelectIndexBlock = ^(NSIndexPath *indexPath,NSInteger markTime) {
        [weakSelf.markTimeSet removeObject:[NSString stringWithFormat:@"%ld",(long)(weakSelf.durationTime + markTime)]];
        NSArray *markTimeArr = [self.markTimeSet allObjects];
        NSArray * tempArr =  [markTimeArr sortedArrayUsingComparator:^NSComparisonResult(NSString  * obj1, NSString * obj2) {
            return [obj1 integerValue]  > [obj2 integerValue] ;
        }];
        markTimeArr = tempArr;
        [weakSelf.markCollectionView updateDataArr:markTimeArr];
    };
    
    
    UILabel *timerLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.view addSubview:timerLab];
    _timerLabel = timerLab;
    timerLab.textColor = [UIColor whiteColor];
    timerLab.text = @"00:00:00";
    timerLab.textAlignment = NSTextAlignmentCenter;
    timerLab.font = [UIFont fontWithName:@"DINAlternate-Bold" size:36];
    [timerLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.markCollectionView.mas_bottom).offset(30);
        make.height.mas_equalTo(42);
    }];
    
    
    UIButton *microphoneBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    [self.view addSubview:microphoneBtn];
    _microphoneBtn = microphoneBtn;
    [microphoneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(timerLab.mas_bottom).offset(40);
        make.width.height.mas_equalTo(68);
    }];
    [microphoneBtn setImage:[UIImage imageNamed:@"icon_microphone"] forState:UIControlStateNormal];
    [microphoneBtn setImage:[UIImage imageNamed:@"in_button_play"] forState:UIControlStateSelected];
    [microphoneBtn addTarget:self action:@selector(recordStart) forControlEvents:UIControlEventTouchUpInside];
    [microphoneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(timerLab.mas_bottom).offset(40);
        make.width.height.mas_equalTo(68);
    }];
    
    CustomImgLabBtn *tagCustomBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 74, 38)];
    [self.view addSubview:tagCustomBtn];
    tagCustomBtn.backgroundColor = UIColorFromRGB(0x3B3B4D);
    tagCustomBtn.layer.cornerRadius = 19;
    tagCustomBtn.clipsToBounds = true;
    [tagCustomBtn setTitle:@"标记" forState:UIControlStateNormal];
    [tagCustomBtn setImage:[UIImage imageNamed:@"in_icon_add_sign"] forState:UIControlStateNormal];
    [tagCustomBtn addTarget:self action:@selector(markAction) forControlEvents:UIControlEventTouchUpInside];
    [tagCustomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(microphoneBtn.mas_left).offset(-35);
        make.centerY.equalTo(microphoneBtn.mas_centerY);
        make.width.mas_equalTo(74);
        make.height.mas_equalTo(38);
    }];
    
    CustomImgLabBtn *saveCustomBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 74, 38)];
    [self.view addSubview:saveCustomBtn];
    saveCustomBtn.backgroundColor = UIColorFromRGB(0x3B3B4D);
    saveCustomBtn.layer.cornerRadius = 19;
    saveCustomBtn.clipsToBounds = true;
    [saveCustomBtn setTitle:@"完成" forState:UIControlStateNormal];
    [saveCustomBtn setImage:[UIImage imageNamed:@"in_icon_finish"] forState:UIControlStateNormal];
    [saveCustomBtn addTarget:self action:@selector(finishRecordAction) forControlEvents:UIControlEventTouchUpInside];
    [saveCustomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(microphoneBtn.mas_right).offset(35);
        make.centerY.equalTo(microphoneBtn.mas_centerY);
        make.width.mas_equalTo(74);
        make.height.mas_equalTo(38);
    }];
    
}

-(void)initAudio{
    
    _audioGraph = [[EAudioGraph alloc]initWithName:@"audioStudio" withType:EAGraphRenderType_RealTime];
    _micSpot = [_audioGraph createMicAudioSpot:@"micPlayer"];
    [_audioGraph addAudioSpot:_micSpot];
    _micSpot.volume = 1.0;
    
    NSString *directPath = [FilePathManager getAudioFileRecordPath];
    if (directPath == nil) {
        return ;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyyMMddhhmmss";
    NSString *localSaveDate = [formatter stringFromDate: [NSDate date]];
    
     NSString *fileFormat = @".wav"; //
    if ([_fileName containsString:@"wav"]) {
        fileFormat = @".wav";
    }else if([_fileName containsString:@"mp3"]){
        fileFormat = @".mp3";
    }else if([_fileName containsString:@"m4a"]){
        fileFormat = @".m4a";
    }
    NSString *voiceRecordName = @"";
    if ([_fileName containsString:@"mp3"]) {
        voiceRecordName = [NSString stringWithFormat:@"%@%@",directPath,_fileName];
    }else{
        voiceRecordName = [NSString stringWithFormat:@"%@%@%@",directPath,localSaveDate,fileFormat];
    }
    __weak typeof (self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2), dispatch_get_main_queue(), ^{
        
        [weakSelf.micSpot startRecordContinueFilePath:voiceRecordName];
        [self resumeRecordAudio];
    });
    _saveRecordName = voiceRecordName;
    _micSpot.onMicDataBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf.audioPlotGLView updateBuffer:data
                                    withBufferSize:numFrames/4];
        });
    };
}



-(void)goBackAction{
    _discard = true;
    [self stopRecordAudio];
    [self.navigationController popViewControllerAnimated:true];
}
-(void)markAction{
    
    NSString *markTime = [NSString stringWithFormat:@"%ld", (long)(self.durationTime + self.timeCount)];
    [self.markTimeSet addObject:markTime];
    NSArray *markTimeArr = [self.markTimeSet allObjects];
    NSArray * tempArr =  [markTimeArr sortedArrayUsingComparator:^NSComparisonResult(NSString  * obj1, NSString * obj2) {
        return [obj1 integerValue]  > [obj2 integerValue] ;
    }];
    markTimeArr = tempArr;
    [_markCollectionView updateDataArr:markTimeArr];
}

-(void)recordStart{
    if (_audioGraph == nil) {
        [self initAudio];
        [self startTimer];
    }else{
        _isPause ? [self resumeRecordAudio] : [self pauseRecordAudio] ;
    }
}
-(void)pauseRecordAudio{
    [_audioGraph stopGraph];
    _isPause = true;
    _microphoneBtn.selected = false;
}
-(void)resumeRecordAudio{
    [_audioGraph startGraph];
    _isPause = false;
    _microphoneBtn.selected = true;
}
-(void)stopRecordAudio{
    if (_discard) {
        [_micSpot resetRecordContinue];
    }else{
        [_micSpot stopRecordContinue];
    }
    [_audioGraph stopGraph];
    [_audioPlotGLView clear];
    [_audioPlotGLView pauseDrawing];
    _audioPlotGLView = nil;
    _isPause = true;
    _micSpot = nil;
    _audioGraph = nil;
    [self.markTimeSet removeAllObjects];
    [self.markCollectionView updateDataArr:[NSMutableArray arrayWithCapacity:1]];
    [self destoryTimer];
    _microphoneBtn.selected = false;
    _timerLabel.text  = [NSString stringWithFormat:@"00:00:00"];
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
    
    NSInteger count = (self.durationTime + self.timeCount);
    NSInteger minutes = count / 60;
    NSInteger seconds =  count % 60;
    NSInteger hours = minutes / 60;
    minutes = minutes % 60;
    NSString *secondStr = seconds < 10 ? [NSString stringWithFormat:@"0%ld",(long)seconds] : [NSString stringWithFormat:@"%ld",(long)seconds];
    NSString *minuteStr = minutes < 10 ? [NSString stringWithFormat:@"0%ld",(long)minutes] : [NSString stringWithFormat:@"%ld",(long)minutes];
    NSString *hourStr = hours < 10 ? [NSString stringWithFormat:@"0%ld",(long)hours] : [NSString stringWithFormat:@"%ld",(long)hours];
    _timerLabel.text  = [NSString stringWithFormat:@"%@:%@:%@",hourStr,minuteStr,secondStr];
    
}

-(void)finishRecordAction{
    if (_audioGraph == nil) {
        return ;
    }
    [self pauseRecordAudio];
    [self stopRecordAudio];
    if ([_fileName containsString:@"mp3"]) {
        return;
    }
    NSString *directPath = [FilePathManager getAudioFileRecordPath];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyyMMddhhmmss";
    NSString *localSaveDate = [formatter stringFromDate: [NSDate date]];
    NSString *fileFormat = @".wav"; //
    if ([_fileName containsString:@"wav"]) {
        fileFormat = @".wav";
    }else if([_fileName containsString:@"m4a"]){
        fileFormat = @".m4a";
    }
    NSString *outputPathName = [NSString stringWithFormat:@"%@%@%@",directPath,localSaveDate,fileFormat];
   NSString * firstRecordName = [NSString stringWithFormat:@"%@%@",directPath,_fileName];
    
    
    [self.activityIndicator startAnimating];
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL status = [EAudioFileRecorder appendTwoFile:firstRecordName secondFilePath: weakSelf.saveRecordName outputFilePath:outputPathName];
        if (status == true) {
            [FilePathManager deleteFileName:firstRecordName];
            [FilePathManager changeFileName:outputPathName newFileName:firstRecordName];
            if (weakSelf.markTimeSet.count > 0) {
                NSArray *dataArr =  [FilePathManager getArchiverModel];
                for (AudioInfoModel *infoModel in  dataArr){
                    if ([infoModel.fileName isEqualToString:weakSelf.fileName]){
                        NSArray *markArr = [weakSelf.markTimeSet allObjects];
                        if (weakSelf.markTimeSet.count > 0) {
                            NSString *markStr = [markArr componentsJoinedByString:@","];
                            NSString *oldMarkTime = infoModel.markTime;
                            if (oldMarkTime.length > 1) {
                                oldMarkTime = [NSString stringWithFormat:@"%@,",oldMarkTime];
                            }
                            infoModel.markTime = [NSString stringWithFormat:@"%@%@",oldMarkTime,markStr];
                        }
                        
                    }
                }
                [FilePathManager updateArchiverModel:[NSMutableArray arrayWithArray:dataArr]];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == true) {
                [weakSelf.activityIndicator stopAnimating];
            }
        });
    });
  
}



@end

//
//  PlayAudioViewController.m
//  INAudioVideoNote
//
//  Created by kunlun on 27/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "PlayAudioViewController.h"
#import <EZAudioIOS/EZAudio.h>
#import <Masonry/Masonry.h>
#import "INConst.h"
#import "CustomImgLabBtn.h"
#import <EAudioKit/EAudioKit.h>
#import "FilePathManager.h"
#import "ContinueRecordViewController.h"
#import "AudioCutViewController.h"
#import "MarkCollectionView.h"
#import "ConvertPopView.h"



@interface PlayAudioViewController ()

@property (nonatomic, strong)  EZAudioPlotGL *audioPlotGLView;
@property(nonatomic,strong) EAudioGraph *audioGraph;
@property(nonatomic,strong) EAudioSpot *audioSpot;
@property(nonatomic,assign) BOOL isPause;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) NSInteger timeCount;
@property(nonatomic,strong)  UILabel *timerLabel;
@property(nonatomic,strong) UIButton *playBtn;
@property(nonatomic,assign) NSInteger startTime;
@property(nonatomic,assign) NSInteger durationTime;
@property(nonatomic,strong) UISlider *playSlider ;
@property(nonatomic,strong) UIDocumentInteractionController *documentController;
@property(nonatomic,strong) UIView  *plotGLBackView;

@end

@implementation PlayAudioViewController

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
    
    UIButton * rightBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    rightBtn.frame = CGRectMake(0, 0, 60,44);
    UIImageView *shareImgView = [[UIImageView alloc]initWithFrame:CGRectMake(60-23, (44-22)/2.0, 23, 22)];
    [rightBtn addSubview:shareImgView];
    shareImgView.contentMode = UIViewContentModeScaleAspectFit;
    shareImgView.image = [UIImage imageNamed:@"icon_share"];
    [rightBtn addTarget:self action:@selector(shareFileAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBarBtn = [[UIBarButtonItem alloc]initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightBarBtn ;
    
}

-(void)initAudioPlotGL{
    
    UIView *plotGLBackView = [[UIView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:plotGLBackView];
    _plotGLBackView = plotGLBackView;
    plotGLBackView.backgroundColor = UIColorFromRGB(0x151515);
    [plotGLBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(0);
        make.height.mas_equalTo(220);
    }];
    
    _audioPlotGLView = [[EZAudioPlotGL alloc]initWithFrame:CGRectZero];
    [plotGLBackView addSubview:_audioPlotGLView];
    [_audioPlotGLView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(plotGLBackView);
        make.width.mas_equalTo(IN_IPHONE_WIDTH/2);
    }];
    _audioPlotGLView.backgroundColor = UIColorFromRGB(0x151515);
    _audioPlotGLView.color           =  UIColorFromRGB(0xFF5700);
    _audioPlotGLView.plotType        = EZPlotTypeRolling;
    _audioPlotGLView.shouldFill      = YES;
    _audioPlotGLView.shouldMirror    = YES;
    _audioPlotGLView.gain = 2.5f;
    [_audioPlotGLView initDefaultBuffer];

    
    UIView *midHorLineView = [[UIView alloc]initWithFrame:CGRectZero];
    [plotGLBackView addSubview:midHorLineView];
    midHorLineView.backgroundColor = UIColorFromRGB(0x3C3226);
    [midHorLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(plotGLBackView);
        make.height.mas_equalTo(1);
        make.centerY.equalTo(plotGLBackView.mas_centerY);
    }];
    UIView *midVerLineView = [[UIView alloc]initWithFrame:CGRectZero];
    [plotGLBackView addSubview:midVerLineView];
    midVerLineView.backgroundColor = UIColorFromRGB(0xFF5700);
    [midVerLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.top.equalTo(plotGLBackView);
        make.centerX.equalTo(plotGLBackView.mas_centerX);
        make.width.mas_equalTo(1);
    }];
}


-(void)initView{
    
    self.title = self.fileName;
    self.isPause = true;
    self.startTime = 0;
    self.view.backgroundColor = UIColorFromRGB(0x2E2D38);
    [self initAudioPlotGL];
   
    _durationTime =  [FilePathManager getAudiodurationTimer:_fileName];

    UIView *sliderView = [[UIView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:sliderView];
    sliderView.backgroundColor = UIColorFromRGB(0x121212);
    [sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.plotGLBackView.mas_bottom);
        make.height.mas_equalTo(30);
    }];
    UISlider *playSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,0,IN_IPHONE_WIDTH,30)];
    [playSlider setMinimumTrackTintColor:UIColorFromRGB(0xFF5700)];
    [playSlider setThumbImage:[UIImage imageNamed:@"in_button_drag"] forState:UIControlStateNormal];
    [playSlider addTarget:self action:@selector(onDragSlider:) forControlEvents:UIControlEventValueChanged];
    playSlider.maximumTrackTintColor = [UIColor whiteColor];
    playSlider.minimumValue = 0;
    playSlider.maximumValue = 50;
    playSlider.value = 5;
    [sliderView addSubview:playSlider];
    _playSlider = playSlider;
    
    MarkCollectionView *markCollectionView = [[MarkCollectionView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:markCollectionView];
    markCollectionView.backgroundColor = UIColorFromRGB(0x1A1A1C);
    [markCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(sliderView.mas_bottom).offset(0);
        make.height.mas_equalTo(40);
    }];
    if (self.infoModel.markTime.length > 1) {
        NSArray *markTimeArr = [self.infoModel.markTime componentsSeparatedByString:@","];
        if (markTimeArr.count > 1) {
         NSArray * tempArr =  [markTimeArr sortedArrayUsingComparator:^NSComparisonResult(NSString  * obj1, NSString * obj2) {
             return [obj1 integerValue]  > [obj2 integerValue] ;
            }];
            markTimeArr = tempArr;
        }
        [markCollectionView updateDataArr:markTimeArr];
        __weak typeof (self) weakSelf = self;
        markCollectionView.markTimeSelectIndexBlock = ^(NSIndexPath *indexPath, NSInteger markTime) {
            [weakSelf.audioGraph setCurrentTime:markTime];
            [weakSelf startPlay];
        };
    }
    
    UILabel *timerLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.view addSubview:timerLab];
    _timerLabel = timerLab;
    timerLab.textColor = [UIColor whiteColor];
    timerLab.text = @"00:00:00";
    timerLab.textAlignment = NSTextAlignmentCenter;
    timerLab.font = [UIFont fontWithName:@"DINAlternate-Bold" size:36];
    [timerLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(markCollectionView.mas_bottom).offset(30);
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
    
    CustomImgLabBtn *tagCustomBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 74, 38)];
    [self.view addSubview:tagCustomBtn];
    tagCustomBtn.backgroundColor = UIColorFromRGB(0x3B3B4D);
    tagCustomBtn.layer.cornerRadius = 19;
    tagCustomBtn.clipsToBounds = true;
    [tagCustomBtn setTitle:@"绪录" forState:UIControlStateNormal];
    [tagCustomBtn setImage:[UIImage imageNamed:@"button_microphone_grey"] forState:UIControlStateNormal];
    [tagCustomBtn addTarget:self action:@selector(continueRecordAction) forControlEvents:UIControlEventTouchUpInside];
    [tagCustomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(playBtn.mas_left).offset(-35);
        make.centerY.equalTo(playBtn.mas_centerY);
        make.width.mas_equalTo(74);
        make.height.mas_equalTo(38);
    }];
    
    CustomImgLabBtn *saveCustomBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 74, 38)];
    [self.view addSubview:saveCustomBtn];
    saveCustomBtn.backgroundColor = UIColorFromRGB(0x3B3B4D);
    saveCustomBtn.layer.cornerRadius = 19;
    saveCustomBtn.clipsToBounds = true;
    [saveCustomBtn setTitle:@"裁剪" forState:UIControlStateNormal];
    [saveCustomBtn setImage:[UIImage imageNamed:@"in_icon_cut_grey"] forState:UIControlStateNormal];
    [saveCustomBtn addTarget:self action:@selector(cutAudioAction) forControlEvents:UIControlEventTouchUpInside];
    [saveCustomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(playBtn.mas_right).offset(35);
        make.centerY.equalTo(playBtn.mas_centerY);
        make.width.mas_equalTo(74);
        make.height.mas_equalTo(38);
    }];
    
    CustomImgLabBtn *convertBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 74, 38)];
    [self.view addSubview:convertBtn];
    convertBtn.backgroundColor = UIColorFromRGB(0x3B3B4D);
    convertBtn.layer.cornerRadius = 19;
    convertBtn.clipsToBounds = true;
    [convertBtn setTitle:@"转码" forState:UIControlStateNormal];
    [convertBtn setImage:[UIImage imageNamed:@"button_microphone_grey"] forState:UIControlStateNormal];
    [convertBtn addTarget:self action:@selector(convertAction) forControlEvents:UIControlEventTouchUpInside];
    [convertBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(playBtn.mas_centerX);
        make.centerY.equalTo(playBtn.mas_bottom).offset(45);
        make.width.mas_equalTo(74);
        make.height.mas_equalTo(38);
    }];
    
   
    
}

-(void)initAudio{
    NSString *filePath = [FilePathManager  getAudioFileRecordPath];
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",filePath,_fileName];
    _audioGraph = [[EAudioGraph alloc] initWithName:@"playAudioGraph" withType:EAGraphRenderType_RealTime];
    EAudioSpot *audioSpot =  [_audioGraph createAudioSpot:filePathName withName:@"recordFilePlayer"];
    [_audioGraph addAudioSpot:audioSpot];
    _audioSpot = audioSpot;
    
    __weak typeof (self) weakSelf = self;
    audioSpot.onPlayDataBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf.audioPlotGLView updateBuffer:data
                                    withBufferSize:numFrames/4];
        });
        
    };
    audioSpot.onPlayEnd = ^(EAudioSpot *spot) {
        [weakSelf playStartAction: nil];
    };
}

-(void)shareFileAction{
    
    NSString *filePath = [FilePathManager  getAudioFileRecordPath];
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",filePath,_fileName];
    UIDocumentInteractionController *documentController = [UIDocumentInteractionController  interactionControllerWithURL:[NSURL fileURLWithPath:filePathName]];
    [documentController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    _documentController = documentController;
    
}

-(void)goBackAction{
    
    [self stopPlay];
    [self.navigationController popViewControllerAnimated:true];
}

-(void)playStartAction:(UIButton*)sendBtn{
    if (_isPause) {
        [self startPlay];
    }else{
        [self pausePlay];
    }
}

-(void)convertAction{
    NSString *filePath = [FilePathManager  getAudioFileRecordPath];
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",filePath,_fileName];
    
    NSString *format = [_fileName pathExtension];
    NSString *noformatName = [_fileName substringToIndex:_fileName.length-4];
    __weak typeof (self) weakSelf = self;
    [ConvertPopView showSelectTitle:format titleIndexBlock:^(NSString * _Nonnull title) {
        
        NSString *targetFormat = [title substringFromIndex:title.length-3];
        if ([targetFormat isEqualToString:format]) {
            return ;
        }
        NSString *targetPathName = [NSString stringWithFormat:@"%@%@.%@",filePath,noformatName,targetFormat];
        BOOL isSucess = [EAudioFileRecorder oneFormatToAudioFile:filePathName targetAudioFile:targetPathName];
        if (isSucess) {
            NSArray *dataArr =  [FilePathManager getArchiverModel];
            NSMutableArray *newDataArr = [NSMutableArray arrayWithCapacity:1];
            [newDataArr addObjectsFromArray:dataArr];
            for (AudioInfoModel *infoModel in  dataArr){
                if ([infoModel.fileName isEqualToString:weakSelf.fileName]){
                    AudioInfoModel *newInfoModel = [[AudioInfoModel alloc]init];
                    newInfoModel.markTime = infoModel.markTime;
                    newInfoModel.dateTime = infoModel.dateTime;
                    newInfoModel.durationTime = infoModel.durationTime;
                    newInfoModel.fileName = [NSString stringWithFormat:@"%@.%@",noformatName,targetFormat];
                    [newDataArr insertObject:newInfoModel atIndex:0];
                    break;
                }
            }

            [FilePathManager updateArchiverModel:[NSMutableArray arrayWithArray:newDataArr]];
            //[FilePathManager deleteFileName:filePathName];
        }
        
    }];
    
}

-(void)pausePlay{
    [_audioGraph stopGraph];
    _isPause = true;
    _playBtn.selected = false;
}
-(void)startPlay{
    [_audioGraph startGraph];
    _isPause = false;
    _playBtn.selected = true;
    [self startTimer];
}


-(void)stopPlay{
    [_audioGraph stopGraph];
    _audioSpot = nil;
    _audioGraph = nil;
    [_audioPlotGLView clear];
    [_audioPlotGLView pauseDrawing];
    _audioPlotGLView = nil;
    _isPause = true;
    [self destoryTimer];
}

-(void)onDragSlider:(UISlider*)slider{
    self.startTime =  slider.value / 50 * self.durationTime;
    self.timeCount = self.startTime;
    [_audioGraph setCurrentTime:self.startTime];
    [self startPlay];
}


-(void)cutAudioAction{
    
    [self pausePlay];

    AudioCutViewController *cutViewController = [[AudioCutViewController alloc]init];
    cutViewController.fileName = _fileName;
    [self.navigationController pushViewController:cutViewController animated:true];
}
-(void)continueRecordAction{
    [self pausePlay];
    ContinueRecordViewController *continueRecordVC = [[ContinueRecordViewController alloc]init];
    continueRecordVC.fileName = _fileName;
    [self.navigationController pushViewController:continueRecordVC animated:true];
}


- (void)startTimer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
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
    self.playSlider.value = self.audioSpot.currentTime * 50 / self.durationTime;
    self.timeCount = self.audioSpot.currentTime;
    NSInteger minutes = self.timeCount / 60;
    NSInteger seconds =  self.timeCount % 60;
    NSInteger hours = minutes / 60;
    minutes = minutes % 60;
    NSString *secondStr = seconds < 10 ? [NSString stringWithFormat:@"0%ld",seconds] : [NSString stringWithFormat:@"%ld",seconds];
    NSString *minuteStr = minutes < 10 ? [NSString stringWithFormat:@"0%ld",minutes] : [NSString stringWithFormat:@"%ld",minutes];
    NSString *hourStr = hours < 10 ? [NSString stringWithFormat:@"0%ld",hours] : [NSString stringWithFormat:@"%ld",hours];
    _timerLabel.text  = [NSString stringWithFormat:@"%@:%@:%@",hourStr,minuteStr,secondStr];
    
}



@end

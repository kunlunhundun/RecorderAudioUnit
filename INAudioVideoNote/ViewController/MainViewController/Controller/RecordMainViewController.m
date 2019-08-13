//
//  ViewController.m
//  INAudioVideoNote
//
//  Created by kunlun on 24/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "RecordMainViewController.h"
#import <Masonry/Masonry.h>
#import <EAudioKit/EAudioKit.h>
#import "FilePathManager.h"
#import <EZAudioIOS/EZAudio.h>
#import "RecordListViewController.h"
#import "INConst.h"
#import "CustomImgLabBtn.h"
#import "AudioInfoModel.h"
#import "PopTableView.h"
#import "MarkCollectionView.h"


@interface RecordMainViewController ()

@property(nonatomic,strong) EAudioSpot *micSpot;
@property(nonatomic,strong) EAudioSpot *playSpot;
@property(nonatomic,strong) EAudioGraph *audioGraph;
@property(nonatomic,assign) BOOL isPause;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) int timeCount;
@property(nonatomic,strong)  UILabel *timerLabel;
@property(nonatomic,strong)  UILabel *formatterNameLab;
@property(nonatomic,strong)  UIButton *microphoneBtn;
@property(nonatomic,strong) NSString *fileRecordName;

@property(nonatomic, strong)  EZAudioPlotGL *audioPlotGLView;
@property(nonatomic,strong) NSString *fileFormat;
@property(nonatomic,strong) NSMutableSet *markTimeSet;
@property(nonatomic,strong) MarkCollectionView *markCollectionView;
@property(nonatomic,strong) UIView  *plotGLBackView;

@property(nonatomic,strong) NSString *playPathRecordName;
@property(nonatomic,assign) BOOL tryPlayState;
@end

@implementation RecordMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setAudioSession];
    [self initAudioPlotGL];
    [self initView];

}

-(void)initAudioPlotGL{
    
    UIView *plotGLBackView = [[UIView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:plotGLBackView];
    _plotGLBackView = plotGLBackView;
    plotGLBackView.backgroundColor = UIColorFromRGB(0x151515);
    [plotGLBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(50);
        make.height.mas_equalTo(220);
    }];
    
    _audioPlotGLView = [[EZAudioPlotGL alloc]initWithFrame:CGRectZero];
    [plotGLBackView addSubview:_audioPlotGLView];
    [_audioPlotGLView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(plotGLBackView);
        make.width.mas_equalTo(IN_IPHONE_WIDTH/2);
    }];
    [_audioPlotGLView setRollingHistoryLength:512/2];
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

-(void)initNavigation{
    UIButton * btn = [[UIButton alloc]initWithFrame:CGRectZero];
    btn.frame = CGRectMake(0, 0, 60,44);
    UIImageView *backImgView = [[UIImageView alloc]initWithFrame:CGRectMake(60-28, (44-24)/2.0, 28, 24)];
    [btn addSubview:backImgView];
    backImgView.contentMode = UIViewContentModeScaleAspectFit;
    backImgView.image = [UIImage imageNamed:@"icon_file_list"];
    [btn addTarget:self action:@selector(goListRecord) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBarBtn = [[UIBarButtonItem alloc]initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = rightBarBtn ;
    
    UILabel * titleLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 60,44)];
    titleLab.text = @"录音";
    titleLab.textColor = [UIColor whiteColor];
    titleLab.font = [UIFont fontWithName:@"PingFangSC-Medium" size:22];
    UIBarButtonItem * leftBarItemBtn = [[UIBarButtonItem alloc]initWithCustomView:titleLab];
    self.navigationItem.leftBarButtonItem = leftBarItemBtn ;
    
    
}

-(void)initView{
    
    self.view.backgroundColor = UIColorFromRGB(0x2E2D38);
    self.markTimeSet = [NSMutableSet setWithCapacity:1];

    [self initNavigation ];
    
    UIView *formatterView = [[UIView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:formatterView];
    [formatterView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.height.mas_equalTo(50);
    }];
    
    UIImageView *sampleImgView = [[UIImageView alloc]initWithFrame:CGRectZero];
    [formatterView addSubview:sampleImgView];
    sampleImgView.image = [UIImage imageNamed:@"in_icon_quality"]; //22 14
    [sampleImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(15);
        make.centerY.equalTo(formatterView.mas_centerY);
        make.width.mas_equalTo(22);
        make.height.mas_equalTo(14);
    }];
    
    UILabel *sampleLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [formatterView addSubview:sampleLab];
    sampleLab.text = @"标准 44100HZ";
    sampleLab.textColor = UIColorFromRGB(0x6D6E71);
    sampleLab.font = [UIFont systemFontOfSize:14];
    [sampleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sampleImgView.mas_right).offset(5);
        make.centerY.equalTo(formatterView.mas_centerY);
        make.width.mas_equalTo(110);
        make.height.mas_equalTo(20);
    }];
    
    _fileFormat = @".wav"; //
    UILabel *formatterNameLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [formatterView addSubview:formatterNameLab];
    formatterNameLab.text = @"格式 wav";
    formatterNameLab.textColor = UIColorFromRGB(0x6D6E71);
    formatterNameLab.font = [UIFont systemFontOfSize:14];
    _formatterNameLab = formatterNameLab;
    [formatterNameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sampleLab.mas_right).offset(30);
        make.centerY.equalTo(formatterView.mas_centerY);
        make.width.mas_equalTo(70);
        make.height.mas_equalTo(20);
    }];
    UIButton *formatBtn = [[UIButton alloc] initWithFrame:CGRectZero];
    [formatterView addSubview:formatBtn];
    [formatBtn setImage : [UIImage imageNamed:@"arow_more"] forState:UIControlStateNormal];
    [formatBtn addTarget:self action:@selector(formatAction) forControlEvents:UIControlEventTouchUpInside];
    [formatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(formatterNameLab.mas_right).offset(0);
        make.centerY.equalTo(formatterView.mas_centerY);
        make.width.height.mas_equalTo(30);
    }];
    
    MarkCollectionView *markCollectionView = [[MarkCollectionView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:markCollectionView];
    markCollectionView.backgroundColor = UIColorFromRGB(0x1A1A1C);
    [markCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.plotGLBackView.mas_bottom).offset(0);
        make.height.mas_equalTo(40);
    }];
    _markCollectionView = markCollectionView;
    markCollectionView.ishowCloseImg = true;
    __weak typeof (self) weakSelf = self;
    markCollectionView.markTimeSelectIndexBlock = ^(NSIndexPath *indexPath,NSInteger markTime) {
        [weakSelf.markTimeSet removeObject:[NSString stringWithFormat:@"%ld",markTime]];
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
        make.top.equalTo(self.audioPlotGLView.mas_bottom).offset(80);
        make.height.mas_equalTo(42);
    }];
    
   
    UIButton *microphoneBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    [self.view addSubview:microphoneBtn];
    [microphoneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(timerLab.mas_bottom).offset(40);
        make.width.height.mas_equalTo(68);
    }];
    [microphoneBtn setImage:[UIImage imageNamed:@"icon_microphone"] forState:UIControlStateNormal];
    [microphoneBtn setImage:[UIImage imageNamed:@"in_button_play"] forState:UIControlStateSelected];
    [microphoneBtn addTarget:self action:@selector(recordStart) forControlEvents:UIControlEventTouchUpInside];
    _microphoneBtn = microphoneBtn;
    
    CustomImgLabBtn *tagCustomBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 74, 38)];
    [self.view addSubview:tagCustomBtn];
    tagCustomBtn.backgroundColor = UIColorFromRGB(0x3B3B4D);
    tagCustomBtn.layer.cornerRadius = 19;
    tagCustomBtn.clipsToBounds = true;
    [tagCustomBtn setTitle:@"标记" forState:UIControlStateNormal];
    [tagCustomBtn setImage:[UIImage imageNamed:@"in_icon_add_sign"] forState:UIControlStateNormal];
    [tagCustomBtn addTarget:self action:@selector(markTimeAction) forControlEvents:UIControlEventTouchUpInside];
    [tagCustomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(microphoneBtn.mas_left).offset(-40);
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
        make.left.equalTo(microphoneBtn.mas_right).offset(40);
        make.centerY.equalTo(microphoneBtn.mas_centerY);
        make.width.mas_equalTo(74);
        make.height.mas_equalTo(38);
    }];
    
  
    CustomImgLabBtn *giveupBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 60, 60) updown:true];
    [self.view addSubview:giveupBtn];
    [giveupBtn setImage:[UIImage imageNamed:@"in_icon_give up"] forState:UIControlStateNormal];
    [giveupBtn setTitle:@"放弃" forState:UIControlStateNormal];
    [giveupBtn  setTitleColor:UIColorFromRGB(0x6D6E71) forState:UIControlStateNormal];
    [giveupBtn addTarget:self action:@selector(giveupAction) forControlEvents:UIControlEventTouchUpInside];
    [giveupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(timerLab.mas_top).offset(-5);
        make.centerX.equalTo(tagCustomBtn.mas_centerX);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(60);
    }];
    
   
    CustomImgLabBtn *tryPlayBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectZero updown:true];
    [self.view addSubview:tryPlayBtn];
    [tryPlayBtn setImage:[UIImage imageNamed:@"icon_mini_microphone"] forState:UIControlStateNormal];
    [tryPlayBtn setTitle:@"试听" forState:UIControlStateNormal];
    [tryPlayBtn  setTitleColor:UIColorFromRGB(0x6D6E71) forState:UIControlStateNormal];
    [tryPlayBtn addTarget:self action:@selector(tryPlayButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [tryPlayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(saveCustomBtn.mas_centerX);
        make.top.equalTo(giveupBtn.mas_top);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(60);
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
    NSString *localSaveDate = [formatter stringFromDate: [NSDate date] ];
    NSString *voiceRecordName = [NSString stringWithFormat:@"%@%@%@",directPath,localSaveDate,_fileFormat];
    NSString *playRecordName = [NSString stringWithFormat:@"%@%@play.pcm",directPath,localSaveDate];
    _playPathRecordName = playRecordName;
    __weak typeof (self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2), dispatch_get_main_queue(), ^{
        
        [weakSelf.micSpot startRecordMutableFormatPath:voiceRecordName];
        [weakSelf.micSpot startRecordRawReadWrite:playRecordName];
        [self resumeRecordAudio];
    });
    
    _fileRecordName = voiceRecordName;
    _micSpot.onMicDataBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf.audioPlotGLView updateBuffer:data
                                    withBufferSize:numFrames/4];
        });
    };
}

-(void)formatAction{
    
    __weak typeof (self) weakSelf = self;
    [PopTableView showSelectTitleIndexBlock:^(NSString * _Nonnull title) {
        if ([title containsString:@"wav"]) {
            weakSelf.fileFormat = @".wav";
        }else if([title containsString:@"mp3"]){
            weakSelf.fileFormat = @".mp3";
        }else if([title containsString:@"m4a"]){
            weakSelf.fileFormat = @".m4a";
        }
        weakSelf.formatterNameLab.text = [NSString stringWithFormat:@"格式 %@",title];
        
    }];
}

-(void)goListRecord{
    
    [self pauseRecordAudio];
    [self.navigationController pushViewController:[[RecordListViewController alloc]init] animated:true];
}

-(void)markTimeAction{
    NSString *markTime = [NSString stringWithFormat:@"%d", self.timeCount];
    [self.markTimeSet addObject:markTime];
    NSArray *markTimeArr = [self.markTimeSet allObjects];

    __weak typeof(self)  weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray * tempArr =  [markTimeArr sortedArrayUsingComparator:^NSComparisonResult(NSString  * obj1, NSString * obj2) {
            return [obj1 integerValue]  > [obj2 integerValue] ;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.markCollectionView updateDataArr:tempArr];
        });
    });
   
}

-(void)finishRecordAction{
    if (_audioGraph == nil) {
        return ;
    }
    [self pauseRecordAudio];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"MMddhhmmss";
    NSString *newName = [formatter stringFromDate: [NSDate date] ];
    __weak typeof(self)  weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"重命名"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    // 2.1 添加文本框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = newName;
    }];
    // 2.2  创建Cancel Login按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
       
    }];
    UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *fileNameField = alertController.textFields.firstObject;
        NSString * fileName = fileNameField.text;
        if (fileName.length > 1) {
            [weakSelf reNameRecordName:fileName];
            [weakSelf stopRecordAudio];
            [weakSelf.navigationController pushViewController: [[RecordListViewController alloc] init] animated:true];
        }
        NSLog(@"name is %@",fileName);
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:loginAction];
    // 3.显示警报控制器
    [self presentViewController:alertController animated:YES completion:nil];

}
-(void)giveupAction{
    
    __weak typeof(self)  weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"放弃本次录音"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (weakSelf.audioGraph == nil) {
            return ;
        }
        [weakSelf pauseRecordAudio];
        [weakSelf stopRecordAudio];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:loginAction];
    // 3.显示警报控制器
    [self presentViewController:alertController animated:YES completion:nil];

}

-(void)tryPlayButtonAction{
     if (_audioGraph == nil) {
         return ;
     }
    if (_tryPlayState == false) {
        _tryPlayState = true;
        [self.micSpot pauseRowRecordForPlay:true];
        _isPause = true;
        [self pauseRecordAudio];
        [_audioGraph startGraph];
    }else{
        [self stopTryPlay];
    }
}
-(void)stopTryPlay{
    _tryPlayState = false;
    [self.micSpot pauseRowRecordForPlay:false];
    [_audioGraph stopGraph];
}


- (void)setAudioSession {
    AVAudioSession * audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

-(void)recordStart{
    if (_tryPlayState == true) {
        [self stopTryPlay];
    }
    if (_audioGraph == nil) {
        [self initAudio];
        [_audioPlotGLView resumeDrawing];
        [self startTimer];
    }else{
        _isPause ? [self resumeRecordAudio] : [self pauseRecordAudio] ;
    }
}


-(void)pauseRecordAudio{
    [_audioGraph stopGraph];
    [_audioPlotGLView pauseDrawing];
    _isPause = true;
    _microphoneBtn.selected = false;
}
-(void)resumeRecordAudio{
    [_audioGraph startGraph];
    [_audioPlotGLView resumeDrawing];

    _isPause = false;
    _microphoneBtn.selected = true;
}
-(void)stopRecordAudio{
    
    [self stopTryPlay];
    [_micSpot stopRecordMutableFormatPath];
    [_audioGraph stopGraph];
    [_audioPlotGLView clear];
    [_audioPlotGLView pauseDrawing];
    [_audioPlotGLView initDefaultBuffer];
    
    [FilePathManager deleteFileName:_playPathRecordName];
    _isPause = true;
    _micSpot = nil;
    _audioGraph = nil;
    _tryPlayState = false;
    [self.markTimeSet removeAllObjects];
    [_markCollectionView updateDataArr:@[]];
    self.timeCount = 0;
    [self destoryTimer];
     _microphoneBtn.selected = false;
    _timerLabel.text  = [NSString stringWithFormat:@"00:00:00"];
}




-(void)reNameRecordName:(NSString*)newName {
    NSString *directPath = [FilePathManager getAudioFileRecordPath];
    if (directPath == nil) {
        return ;
    }
    NSString *newFileName = [NSString stringWithFormat:@"%@%@%@",directPath,newName,_fileFormat];
    [FilePathManager changeFileName:_fileRecordName newFileName:newFileName];
    _fileRecordName = newFileName;
   
    AudioInfoModel *infoModel = [[AudioInfoModel alloc]init];
    infoModel.fileName = [NSString stringWithFormat:@"%@%@",newName,_fileFormat];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy/MM/dd hh:mm:ss";
    NSString *localSaveDate = [formatter stringFromDate: [NSDate date] ];
    infoModel.dateTime = localSaveDate;
    if (self.markTimeSet.count > 0) {
        NSArray *markArr = [self.markTimeSet allObjects];
        infoModel.markTime = [markArr componentsJoinedByString:@","];
    }
    [FilePathManager saveArchiverModel:infoModel];
    
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

//
//  RecordListViewController.m
//  INAudioVideoNote
//
//  Created by kunlun on 26/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "RecordListViewController.h"
#import <Masonry/Masonry.h>
#import "RecordListView.h"
#import "INConst.h"
#import "PlayAudioViewController.h"
#import "FilePathManager.h"
#import "AudioInfoModel.h"
@interface RecordListViewController ()

@property(nonatomic,strong) RecordListView *listView;
@property(nonatomic,strong) NSArray *recordDataArr;
@property(nonatomic,assign) BOOL isFirstLoad;

@end

@implementation RecordListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (_isFirstLoad == false) {
        NSArray *dataArr =  [FilePathManager getArchiverModel];
        [_listView updateTableViewData:dataArr];
        _recordDataArr = dataArr;
    }
     _isFirstLoad = false;
}


-(void)initView{
 
    _isFirstLoad = true;
    self.title = @"全部录音";
    self.view.backgroundColor = UIColorFromRGB(0x2E2D38);
    [self initNavigation];
    RecordListView *listView = [[RecordListView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:listView];
    _listView = listView;
    listView.weakController = self;
    [listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.view);
    }];
    NSArray *dataArr =  [FilePathManager getArchiverModel];
    [listView updateTableViewData:dataArr];
    _recordDataArr = dataArr;
     __weak typeof(self)   weakSelf = self;
    listView.selectTableViewIndexBlock = ^(NSInteger indexRow) {
        AudioInfoModel *infoModel = weakSelf.recordDataArr[indexRow];
        PlayAudioViewController *playViewController = [[PlayAudioViewController alloc]init];
        playViewController.fileName = infoModel.fileName;
        playViewController.infoModel = infoModel;
       [weakSelf.navigationController pushViewController:playViewController animated:true];
    };
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
    
    UIButton *rightBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    rightBtn.frame = CGRectMake(0, 0, 60,44);
    [rightBtn setTitle:@"编辑" forState:UIControlStateNormal];
    [rightBtn setTitle:@"完成" forState:UIControlStateSelected];

    rightBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [rightBtn addTarget:self action:@selector(editAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBarBtn = [[UIBarButtonItem alloc]initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightBarBtn ;
    
}

-(void)goBackAction{
    [self.navigationController popViewControllerAnimated:true];
}

-(void)editAction:(UIButton*)sendBtn{
    sendBtn.selected = !sendBtn.isSelected;
    [_listView updateWithEdit:sendBtn.isSelected];
 
}


@end

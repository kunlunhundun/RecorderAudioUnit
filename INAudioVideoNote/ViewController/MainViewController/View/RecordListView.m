//
//  RecordListView.m
//  INAudioVideoNote
//
//  Created by kunlun on 26/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "RecordListView.h"
#import <Masonry/Masonry.h>
#import "INConst.h"
#import "RecordListViewCell.h"
#import "FilePathManager.h"
#import "AudioInfoModel.h"
#import "RecordListViewController.h"


@interface RecordListView()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSMutableArray *dataArr;
@property(nonatomic,assign) BOOL isEdit;
@property(nonatomic,strong) UIDocumentInteractionController *documentController;

@end


@implementation RecordListView

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame: frame];
    if (self) {
        UITableView *tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = UIColorFromRGB(0x2E2D38);
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self addSubview:tableView];
        _tableView = tableView;
        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self);
        }];
        
        _dataArr = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}

-(void)updateTableViewData:(NSArray*)dataArr{
    [_dataArr removeAllObjects];
    [_dataArr addObjectsFromArray:dataArr];
    [_tableView reloadData];
}

-(void)updateWithEdit:(BOOL)isEdit{
    _isEdit = isEdit;
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataArr.count;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    RecordListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecordListTableViewCell"];
    if (cell == nil) {
        cell = [[RecordListViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RecordListTableViewCell"];
        cell.selectionStyle = UITableViewCellSeparatorStyleNone;
        cell.backgroundColor = UIColorFromRGB(0x2E2D38);
    }
    AudioInfoModel *infoModel = _dataArr[indexPath.row];
    cell.dateTimeLab.text = infoModel.dateTime;
    
    NSString *fileName =  infoModel.fileName;//_dataArr[indexPath.row];
    NSInteger dateTimeCount =  [FilePathManager getAudiodurationTimer:fileName];
    NSInteger minutes = dateTimeCount / 60;
    NSInteger seconds =  dateTimeCount % 60;
    NSInteger hours = minutes / 60;
    minutes = minutes % 60;
    NSString *secondStr = seconds < 10 ? [NSString stringWithFormat:@"0%ld",seconds] : [NSString stringWithFormat:@"%ld",seconds];
    NSString *minuteStr = minutes < 10 ? [NSString stringWithFormat:@"0%ld",minutes] : [NSString stringWithFormat:@"%ld",minutes];
    NSString *hourStr = hours < 10 ? [NSString stringWithFormat:@"0%ld",hours] : [NSString stringWithFormat:@"%ld",hours];
    cell.timeLab.text  = [NSString stringWithFormat:@"%@:%@:%@",hourStr,minuteStr,secondStr];

    NSString *directPath = [FilePathManager getAudioFileRecordPath];
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",directPath,fileName];
    NSInteger fileSize = [FilePathManager getFileSize:filePathName];
    if (fileSize > 1000) {
        CGFloat mfileSize = (CGFloat)fileSize / (CGFloat)1024 ;
        cell.sizeLab.text = [NSString stringWithFormat:@"%.2f %@",mfileSize,@"MB"];
    }else{
        cell.sizeLab.text = [NSString stringWithFormat:@"%ld %@",fileSize,@"kb"];
    }
    cell.nameLab.text = fileName;
    cell.flagLab.text = @"0";
    if (infoModel.markTime.length > 0) {
        NSArray *markTimeArr =  [infoModel.markTime componentsSeparatedByString:@","];
        cell.flagLab.text = [NSString stringWithFormat:@"%ld",markTimeArr.count];
    }
    if (_isEdit) {
        cell.renameBtn.hidden = false;
        cell.deleteBtn.hidden = false;
    }else{
        cell.renameBtn.hidden = true;
        cell.deleteBtn.hidden = true;
    }
    cell.indexPath = indexPath;
    __weak typeof(self) weakSelf = self;
    cell.tableViewCellTouchUpInsideBlock = ^(NSIndexPath *indexPath, int tag) {
        if (tag == 0) { //导出
            UIDocumentInteractionController *documentController = [UIDocumentInteractionController  interactionControllerWithURL:[NSURL fileURLWithPath:filePathName]];
            [documentController presentOpenInMenuFromRect:CGRectZero inView:weakSelf.weakController.view animated:YES];
            weakSelf.documentController = documentController;
        }else if(tag == 1) { //重命名
            [self renameFilePath:infoModel];
        }else if(tag == 2) { //删除
            [weakSelf.dataArr removeObjectAtIndex:indexPath.row];
            [FilePathManager updateArchiverModel:weakSelf.dataArr];
            [FilePathManager deleteFileName:filePathName];
            [weakSelf.tableView reloadData];
        }
    };
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return (_isEdit ? 74+10+40 : 74+15 ) ;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (_selectTableViewIndexBlock) {
        _selectTableViewIndexBlock(indexPath.row);
    }
}

-(void)renameFilePath:(AudioInfoModel*) audioInfoModel{
    if (_weakController == nil) {
        return ;
    }
    typeof(self) __weak weakSelf = self;
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
          
            NSString *directPath = [FilePathManager getAudioFileRecordPath];
            if (directPath == nil) {
                return ;
            }
            NSString *fileFormat = @".wav";
            NSString *originalName = audioInfoModel.fileName;
            if ([originalName containsString:@"wav"]) {
               fileFormat = @".wav";
            }else if([originalName containsString:@"mp3"]){
                fileFormat = @".mp3";
            }else if([originalName containsString:@"m4a"]){
                fileFormat = @".m4a";
            }
            NSString *newFileName = [NSString stringWithFormat:@"%@%@%@",directPath,fileName,fileFormat];
            NSString *originalPathName = [NSString stringWithFormat:@"%@%@",directPath,originalName];

            [FilePathManager changeFileName:originalPathName newFileName:newFileName];
            
            audioInfoModel.fileName = [NSString stringWithFormat:@"%@%@",fileName,fileFormat];
   
            [FilePathManager updateArchiverModel:weakSelf.dataArr];
        }
        NSLog(@"name is %@",fileName);
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:loginAction];
    // 3.显示警报控制器
    [_weakController presentViewController:alertController animated:YES completion:nil];
}


@end

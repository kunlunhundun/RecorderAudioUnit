//
//  RecordListViewCell.m
//  INAudioVideoNote
//
//  Created by kunlun on 26/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "RecordListViewCell.h"
#import <Masonry/Masonry.h>
#import "INConst.h"

@interface RecordListViewCell()




@end


@implementation RecordListViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupView];
    }
    return self;
}

-(void)setupView{
    
    UIView *lineView = [[UIView alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:lineView];
    lineView.backgroundColor = UIColorFromRGB(0x494949);
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self);
        make.height.mas_equalTo(0.5);
    }];
    UIImageView *voiceImgView = [[UIImageView alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:voiceImgView];
    voiceImgView.image = [UIImage imageNamed:@"icon_mini_microphone"];
    [voiceImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(15);
        make.top.equalTo(self).offset(18);
        make.height.mas_equalTo(22);
        make.width.mas_equalTo(15);
    }];
    UILabel *nameLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:nameLab];
    nameLab.textColor = [UIColor whiteColor];
    nameLab.font = [UIFont systemFontOfSize:18];
    [nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(voiceImgView.mas_right).offset(5);
        make.top.equalTo(self).offset(10);
        make.height.mas_equalTo(22);
        make.right.equalTo(self).offset(90);
    }];
    _nameLab = nameLab;
    
    UILabel *timeLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:timeLab];
    timeLab.textColor = [UIColor whiteColor];
    timeLab.textAlignment = NSTextAlignmentRight;
    timeLab.font = [UIFont systemFontOfSize:16];
    [timeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-15);
        make.width.mas_equalTo(72);
        make.height.mas_equalTo(20);
        make.centerY.equalTo(nameLab.mas_centerY);
    }];
    _timeLab = timeLab;
    
    UILabel *dateTimeLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:dateTimeLab];
    dateTimeLab.textColor = UIColorFromRGB(0x6D6E71);
    dateTimeLab.font = [UIFont systemFontOfSize:14];
    [dateTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(voiceImgView.mas_right).offset(5);
        make.top.equalTo(nameLab.mas_bottom).offset(3);
        make.height.mas_equalTo(20);
        make.right.equalTo(self).offset(90);
    }];
    _dateTimeLab = dateTimeLab;
  
    UIButton *exportBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:exportBtn];
    [exportBtn setImage:[UIImage imageNamed:@"icon_share"] forState:UIControlStateNormal];
    [exportBtn addTarget:self action:@selector(exportAction) forControlEvents:UIControlEventTouchUpInside];
    [exportBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-15);
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(20);
        make.centerY.equalTo(dateTimeLab.mas_centerY);
    }];
    
    UILabel *sizeLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:sizeLab];
    _sizeLab = sizeLab;
    sizeLab.textColor = UIColorFromRGB(0x6D6E71);
    sizeLab.textAlignment = NSTextAlignmentLeft;
    sizeLab.font = [UIFont systemFontOfSize:16];
    [sizeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(dateTimeLab.mas_left);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(20);
        make.top.equalTo(dateTimeLab.mas_bottom).offset(5);
    }];
    
    UILabel *flagLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:flagLab];
    flagLab.textColor = UIColorFromRGB(0x6D6E71);
    flagLab.text = @"0";
    _flagLab = flagLab;
    flagLab.textAlignment = NSTextAlignmentRight;
    flagLab.font = [UIFont systemFontOfSize:16];
    [flagLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-15-20);
        make.width.mas_equalTo(72);
        make.height.mas_equalTo(20);
        make.top.equalTo(sizeLab.mas_top);
    }];
    UIImageView *flagImgView = [[UIImageView alloc]initWithFrame:CGRectZero];
    flagImgView.image = [UIImage imageNamed:@"in_icon_flag"];
    [self.contentView addSubview:flagImgView];
    [flagImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-15);
        make.centerY.equalTo(flagLab.mas_centerY);
        make.width.mas_equalTo(15);
        make.height.mas_equalTo(16);
    }];
    
    CustomImgLabBtn *renameBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 80, 40)];
    [self.contentView addSubview:renameBtn];
    [renameBtn setImage:[UIImage imageNamed:@"in_icon_rename"] forState:UIControlStateNormal];
    [renameBtn setTitle:@"重命名" forState:UIControlStateNormal];
    [renameBtn setTitleColor:UIColorFromRGB(0xFF5700) forState:UIControlStateNormal];
    _renameBtn = renameBtn;
    renameBtn.hidden = true;
    [renameBtn addTarget:self action:@selector(renameAction) forControlEvents:UIControlEventTouchUpInside];

    [renameBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-120);
        make.top.equalTo(self).offset(74+10);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(40);
    }];
    CustomImgLabBtn *deleteBtn = [[CustomImgLabBtn alloc]initWithFrame:CGRectMake(0, 0, 70, 40)];
    [self.contentView addSubview:deleteBtn];
    [deleteBtn setImage:[UIImage imageNamed:@"in_icon_delete"] forState:UIControlStateNormal];
    [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [deleteBtn setTitleColor:UIColorFromRGB(0xFF5700) forState:UIControlStateNormal];
    _deleteBtn = deleteBtn;
    deleteBtn.hidden = true;
    [deleteBtn addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-28);
        make.top.equalTo(self).offset(74+10);
        make.width.mas_equalTo(70);
        make.height.mas_equalTo(40);
    }];
    
}



-(void)exportAction {
    if (_tableViewCellTouchUpInsideBlock) {
        _tableViewCellTouchUpInsideBlock(_indexPath,0);
    }
}
-(void)renameAction{
    if (_tableViewCellTouchUpInsideBlock) {
        _tableViewCellTouchUpInsideBlock(_indexPath,1);
    }
}
-(void)deleteAction{
    if (_tableViewCellTouchUpInsideBlock) {
        _tableViewCellTouchUpInsideBlock(_indexPath,2);
    }
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

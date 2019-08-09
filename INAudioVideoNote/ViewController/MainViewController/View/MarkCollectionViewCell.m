//
//  MarkCollectionViewCell.m
//  INAudioVideoNote
//
//  Created by kunlun on 07/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "MarkCollectionViewCell.h"
#import <Masonry/Masonry.h>
#import "INConst.h"

@implementation MarkCollectionViewCell

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}
-(void)setupView{
    UIImageView *flagImgView = [[UIImageView alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:flagImgView];
    flagImgView.image = [UIImage imageNamed:@"in_icon_flag"];
    [flagImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.width.mas_equalTo(15);
        make.height.mas_equalTo(16);
    }];
    UILabel *numLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [flagImgView addSubview:numLab];
    numLab.text = @"1";
    numLab.textColor = UIColorFromRGB(0x1A1A1C);
    numLab.font = [UIFont systemFontOfSize:8];
    numLab.textAlignment = NSTextAlignmentCenter;
    [numLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(flagImgView.mas_centerX);
        make.top.equalTo(flagImgView).offset(1);
        make.width.height.mas_equalTo(10);
    }];
    _numLab = numLab;
    
    UILabel *timeLab = [[UILabel alloc]initWithFrame:CGRectZero];
    [self.contentView addSubview:timeLab];
    timeLab.text = @"00:00:00";
    timeLab.textColor = UIColorFromRGB(0x6D6E71);
    timeLab.font = [UIFont systemFontOfSize:14];
    [timeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(flagImgView.mas_right).offset(5);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.height.mas_equalTo(20);
    }];
    _timeLab = timeLab;
    
    UIImageView *closeImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
    closeImgView.image = [UIImage imageNamed:@"in_icon_close_falg"];
    [self.contentView addSubview:closeImgView];
    [closeImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(timeLab.mas_right).offset(3);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.width.height.mas_equalTo(22);
    }];
    closeImgView.hidden = true;
    _closeImgView = closeImgView;
    
    
}


@end

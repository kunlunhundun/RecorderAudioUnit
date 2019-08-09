//
//  PopTableView.m
//  INAudioVideoNote
//
//  Created by kunlun on 31/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "PopTableView.h"
#import "INConst.h"

@interface PopTableView()

@property(nonatomic,strong) UIView *maskView;

@property(nonatomic,strong) UIButton *maskButton;

@property(nonatomic,copy) SelectTitleIndexBlock selectTitleIndexBlock;

@property(nonatomic,strong) NSArray *dataArr;

@end


@implementation PopTableView


+(void)showSelectTitleIndexBlock:(SelectTitleIndexBlock)selectTitleBlock{
    
    PopTableView *popView = [[PopTableView alloc]init];
    popView.selectTitleIndexBlock = selectTitleBlock;
    [popView show];
}

-(id)init{
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self) {
        [self setupView];
    }
    return self;
}


-(void)setupView{
    
    self.maskView = [[UIView alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    self.maskView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.maskView];
    
    self.maskButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.maskButton.frame = [[UIScreen mainScreen] bounds];
    [self.maskButton addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.maskView addSubview:self.maskButton];
    
    
    CGFloat width = 100;
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(30, STATUS_NAVI_HEIGHT+50, width, 105)];
    backView.backgroundColor = [UIColor whiteColor];
    [self.maskView addSubview:backView];
    backView.backgroundColor = UIColorFromRGB(0x4A4A4A);
    backView.layer.cornerRadius = 3.0;
 //   backView.userInteractionEnabled = true;
    
    UIImageView *upArrowView = [[UIImageView alloc]initWithFrame:CGRectMake(width-30, -7, 17, 7)];
    [backView addSubview:upArrowView];
    upArrowView.image = [UIImage imageNamed:@"in_upfill_arrow"];
    
   _dataArr = @[@"wav",@"m4a",@"mp3"];
    
    CGFloat height = 35;
    for (int i = 0; i < _dataArr.count; i++ ) {
        UIButton *btn = [[UIButton alloc ]initWithFrame:CGRectMake(0, 0+height*i, width, height)];
        [backView addSubview:btn];
        btn.tag = i + 100;
        [btn setTitle:_dataArr[i] forState:UIControlStateNormal];
        [btn setTitleColor: UIColorFromRGB(0x9B9B9B) forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)btnAction:(UIButton*)btn{
    if (_selectTitleIndexBlock) {
        _selectTitleIndexBlock(_dataArr[btn.tag-100]);
        [self hiden];
    }
}

-(void)show{
    self.hidden = NO;
    [[[[UIApplication sharedApplication] delegate] window] addSubview:self];
}

- (void)btnClick:(id)sender
{
    [self removeFromSuperview];
    self.hidden = YES;
}

-(void)hiden{
    [self removeFromSuperview];
    self.hidden = YES;
}


@end

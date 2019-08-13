//
//  ConvertPopView.m
//  INAudioVideoNote
//
//  Created by kunlun on 12/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "ConvertPopView.h"
#import "INConst.h"
#import <Masonry/Masonry.h>


@interface ConvertPopView()

@property(nonatomic,strong) NSArray *dataArr;

@property(nonatomic,strong) UIView *maskView;

@property(nonatomic,strong) UIButton *maskButton;

@property(nonatomic,copy) SelectPopTitleIndexBlock selectTitleIndexBlock;
@property(nonatomic,strong) NSString *defaultFormat;

@property(nonatomic,assign) NSInteger index;

@property(nonatomic,strong) UIImageView *imgView0;
@property(nonatomic,strong) UIImageView *imgView1;


@end


@implementation ConvertPopView

-(id)initWithTitle:(NSString*)title{
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self) {
        _index = 0;
        _defaultFormat = title;
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
    
    
    CGFloat width = IN_IPHONE_WIDTH-20*2;
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(20, IN_IPHONE_HEIGHT/2-150/2 , width, 150)];
    [self.maskView addSubview:backView];
    backView.backgroundColor = UIColorFromRGB(0x4A4A4A);
    backView.layer.cornerRadius = 3.0;
    _dataArr = @[@"wav",@"m4a",@"mp3"];
    if ([_defaultFormat containsString:@"mp3"]) {
        _dataArr = @[@"wav",@"m4a"];
    }
    if ([_defaultFormat containsString:@"wav"]) {
        _dataArr = @[@"m4a",@"mp3"];
    }if ([_defaultFormat containsString:@"m4a"]) {
        _dataArr =  @[@"wav",@"mp3"];
    }
    CGFloat height = 50;
    for (int i = 0; i < _dataArr.count; i++ ) {
        
        UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 0+height*i+14, 22, 22)];
        [backView addSubview:imgView];
        imgView.image = [UIImage imageNamed:@"in_btn_select"];
        _imgView1 = imgView;
        if (i == 0) {
            imgView.image = [UIImage imageNamed:@"in_btn_select_s"];
            _imgView0 = imgView;
        }
        UIButton *btn = [[UIButton alloc ]initWithFrame:CGRectMake(0, 0+height*i, width, height)];
        [backView addSubview:btn];
        btn.tag = i + 100;
        NSString *titleStr = [NSString stringWithFormat:@"%@转%@",_defaultFormat,_dataArr[i]];
        [btn setTitle:titleStr forState:UIControlStateNormal];
        [btn setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        
       
        UIView *seLineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0+height*i+height, width, 0.6)];
        [backView addSubview:seLineView];
        seLineView.backgroundColor = UIColorFromRGB(0x3C3226);
    }
    UIButton *cancelBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, height*2, width/2, height)];
    [backView addSubview:cancelBtn];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchDown];
    
    UIButton *sureBtn = [[UIButton alloc]initWithFrame:CGRectMake(width/2, height*2, width/2, height)];
    [backView addSubview:sureBtn];
    [sureBtn setTitle:@"确定" forState:UIControlStateNormal];
    [sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sureBtn addTarget:self action:@selector(sureAction) forControlEvents:UIControlEventTouchDown];

    UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(width/2, height*2, 0.6, height)];
    [backView addSubview:lineView];
    lineView.backgroundColor = UIColorFromRGB(0x3C3226);
    
}


+(void)showSelectTitle:(NSString*)title  titleIndexBlock:(SelectPopTitleIndexBlock)selectTitleBlock{
    
    ConvertPopView *popView = [[ConvertPopView alloc]initWithTitle:title];
    popView.defaultFormat = title;
    popView.selectTitleIndexBlock = selectTitleBlock;
    [popView show];
}


-(void)btnAction:(UIButton*)btn{
    _index = btn.tag -100;
    if (_index == 0) {
        _imgView1.image = [UIImage imageNamed:@"in_btn_select"];
        _imgView0.image = [UIImage imageNamed:@"in_btn_select_s"];

    }else{
        _imgView1.image = [UIImage imageNamed:@"in_btn_select_s"];
        _imgView0.image = [UIImage imageNamed:@"in_btn_select"];
    }
}

-(void)cancelAction{
    [self hiden];
}
-(void)sureAction{
    
    if (_selectTitleIndexBlock) {
        _selectTitleIndexBlock(_dataArr[_index]);
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

//
//  CustomImgLab.m
//  INAudioVideoNote
//
//  Created by kunlun on 27/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "CustomImgLabBtn.h"

@interface CustomImgLabBtn()

@property(nonatomic,assign) BOOL updown;

@end

@implementation CustomImgLabBtn


-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame updown:(BOOL)updown{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        self.updown = true;
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];

    if (self.updown) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.imageView.frame = CGRectMake(self.frame.size.width/2-self.imageView.frame.size.width/2, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置x居中
        self.imageView.frame =  CGRectMake(self.imageView.frame.origin.x, 5, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置Y方向
        self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置宽高
        
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, 50, 22); //设置x
        self.titleLabel.frame =  CGRectMake(self.frame.size.width/2-self.titleLabel.frame.size.width/2, self.imageView.frame.size.height+self.imageView.frame.origin.y+5, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height); //设置Y方向
       // self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, self.frame.size.width, 22); //设置宽高
    
    }else{
        self.imageView.frame = CGRectMake(15, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置x坐标
        self.imageView.frame =  CGRectMake(self.imageView.frame.origin.x, self.frame.size.height/2 - self.imageView.frame.size.height/2, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置Y方向居中
        self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置宽高
        
        
        self.titleLabel.frame = CGRectMake(self.imageView.frame.origin.x+self.imageView.frame.size.width+5, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
        self.titleLabel.frame =  CGRectMake(self.titleLabel.frame.origin.x, self.frame.size.height/2 - self.titleLabel.frame.size.height/2, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, 50, 22);
    }

}




@end

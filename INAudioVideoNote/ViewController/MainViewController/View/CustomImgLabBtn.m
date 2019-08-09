//
//  CustomImgLab.m
//  INAudioVideoNote
//
//  Created by kunlun on 27/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "CustomImgLabBtn.h"

@implementation CustomImgLabBtn


-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];


    self.imageView.frame = CGRectMake(15, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置x坐标
   self.imageView.frame =  CGRectMake(self.imageView.frame.origin.x, self.frame.size.height/2 - self.imageView.frame.size.height/2, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置Y方向居中
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height); //设置宽高
    
    
    self.titleLabel.frame = CGRectMake(self.imageView.frame.origin.x+self.imageView.frame.size.width+5, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
    self.titleLabel.frame =  CGRectMake(self.titleLabel.frame.origin.x, self.frame.size.height/2 - self.titleLabel.frame.size.height/2, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
    self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, 50, 22);

}


@end

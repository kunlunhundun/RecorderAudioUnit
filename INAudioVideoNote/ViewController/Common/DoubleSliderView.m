//
//  DoubleSliderView.m
//  INAudioVideoNote
//
//  Created by kunlun on 06/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "DoubleSliderView.h"
#import "UIView+Extension.h"


typedef NS_ENUM(NSUInteger,DragOrientation){
    DragOrientation_Out,
    DragOrientation_Left,
    DragOrientation_Right,
    DragOrientation_OverLap
};

@interface DoubleSliderView()

//手势起手位置类型 0 未在按钮上 not on button ; 1 在左边按钮上 on left button ; 2 在右边按钮上 on right button ; 3 两者重叠 overlap
@property (nonatomic, assign) DragOrientation dragType;
@property (nonatomic, assign) CGFloat minIntervalWidth;
@property (nonatomic, assign) CGPoint leftCenter;//左侧按钮的中心位置 left btn's center
@property (nonatomic, assign) CGPoint rightCenter;//右侧按钮的中心位置 right btn's center
@property (nonatomic, assign) CGFloat marginCenterX;

@property (nonatomic, strong) UIView   *minLineView;
@property (nonatomic, strong) UIView   *maxLineView;
@property (nonatomic, strong) UIView   *midLineView;
@property (nonatomic, strong) UIButton *leftSliderBtn;
@property (nonatomic, strong) UIButton *rightSliderBtn;

@end

@implementation DoubleSliderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        if (self.height < 28 ) {
            self.height = 28;
        }
        self.marginCenterX = 14;
        [self createUI];
    }
    return self;
}


- (void)createUI {

    [self addSubview:self.leftSliderBtn];
    [self addSubview:self.rightSliderBtn];
    self.curMinValue = 0;
    self.curMaxValue = 1;
    
    CGFloat centerY = self.height * 0.5;
    self.leftSliderBtn.centerY = centerY;
    self.rightSliderBtn.centerY = centerY;
    self.leftSliderBtn.x = 0;
    self.rightSliderBtn.right = self.width;

    [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sliderBtnPanAction:)]];

}

-(void)sliderBtnPanAction: (UIPanGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    CGPoint translation = [gesture translationInView:self];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGRect leftSliderFrame = CGRectMake(self.leftSliderBtn.x - 10, self.leftSliderBtn.y - 10, self.leftSliderBtn.width + 20, self.leftSliderBtn.height + 20);
          CGRect rightSliderFrame = CGRectMake(self.rightSliderBtn.x - 10, self.rightSliderBtn.y - 10, self.rightSliderBtn.width + 20, self.rightSliderBtn.height + 20);
        BOOL inLeftSliderBtn = CGRectContainsPoint(leftSliderFrame, location);
        BOOL inRightSliderBtn = CGRectContainsPoint(rightSliderFrame, location);
        if (inLeftSliderBtn && !inRightSliderBtn) {
            NSLog(@"从左边开始触摸 start drag from left");
            self.dragType = DragOrientation_Left;
        }else if (!inLeftSliderBtn && inRightSliderBtn) {
            NSLog(@"从右边开始触摸 start drag from right");
            self.dragType = DragOrientation_Right;
        }else if (!inRightSliderBtn && !inLeftSliderBtn) {
            NSLog(@"没有触动到按钮 not on button");
            self.dragType = DragOrientation_Out;
        }else {
            CGFloat leftOffset = fabs(location.x - self.leftSliderBtn.centerX);
            CGFloat rightOffset = fabs(location.x - self.rightSliderBtn.centerX);
            if (leftOffset > rightOffset) {
                NSLog(@"挨着，往右边 start drag from right");
                self.dragType = DragOrientation_Right;
            }else if (leftOffset < rightOffset) {
                NSLog(@"挨着，往左边 start drag from left");
                self.dragType = DragOrientation_Left;
            }else {
                NSLog(@"正中间 overlap");
                self.dragType = DragOrientation_OverLap;
            }
        }
        if (self.dragType == DragOrientation_Left) {
            self.leftCenter = self.leftSliderBtn.center;
            [self bringSubviewToFront:self.leftSliderBtn];
        }else if (self.dragType == DragOrientation_Right) {
            self.rightCenter = self.rightSliderBtn.center;
            [self bringSubviewToFront:self.rightSliderBtn];
        }
        if (self.minInterval > 0) {
            self.minIntervalWidth = (self.width - self.marginCenterX * 2) * self.minInterval;
        }
    }
    else if (gesture.state == UIGestureRecognizerStateChanged){
        if (self.dragType == DragOrientation_OverLap) {
            if (translation.x > 0) { //从中间往右 from center to right
                self.dragType = DragOrientation_Right;
                self.rightCenter = self.rightSliderBtn.center;
                [self bringSubviewToFront:self.rightSliderBtn];
                
            }else if(translation.x < 0) { //从中间往左 from center to left
                self.dragType = DragOrientation_Left;
                self.leftCenter = self.leftSliderBtn.center;
                [self bringSubviewToFront:self.leftSliderBtn];
            }
        }
        if (self.dragType != DragOrientation_Out && self.dragType != DragOrientation_OverLap) {
            if (self.dragType == DragOrientation_Left) {
                self.leftSliderBtn.center = CGPointMake(self.leftCenter.x + translation.x, self.leftCenter.y);
                if (self.leftSliderBtn.right > self.rightSliderBtn.right - self.minIntervalWidth) {
                    self.leftSliderBtn.right = self.rightSliderBtn.right - self.minIntervalWidth;
                }else {
                    if (self.leftSliderBtn.centerX < self.marginCenterX) {
                        self.leftSliderBtn.centerX = self.marginCenterX;
                    }
                    if (self.leftSliderBtn.centerX > self.width - self.marginCenterX) {
                        self.leftSliderBtn.centerX = self.width - self.marginCenterX;
                    }
                }
                if (self.sliderBtnChangePointBlock != nil) {
                    self.sliderBtnChangePointBlock(self.leftSliderBtn.center, self.rightSliderBtn.center);
                }
               // [self changeLineViewWidth];
              //  [self changeValueFromLocation];
                
            }else {
                self.rightSliderBtn.center = CGPointMake(self.rightCenter.x + translation.x, self.rightCenter.y);
                if (self.rightSliderBtn.x < self.leftSliderBtn.x + self.minIntervalWidth) {
                    self.rightSliderBtn.x = self.leftSliderBtn.x + self.minIntervalWidth;
                }else {
                    if (self.rightSliderBtn.centerX < self.marginCenterX) {
                        self.rightSliderBtn.centerX = self.marginCenterX;
                    }
                    if (self.rightSliderBtn.centerX > self.width - self.marginCenterX) {
                        self.rightSliderBtn.centerX = self.width - self.marginCenterX;
                    }
                }
                
                if (self.sliderBtnChangePointBlock != nil) {
                    self.sliderBtnChangePointBlock(self.leftSliderBtn.center, self.rightSliderBtn.center);
                }
               // [self changeLineViewWidth];
              //  [self changeValueFromLocation];
            }
        }
    }
    
    
}

//改变值域的线宽
- (void)changeLineViewWidth {

    self.minLineView.width = self.leftSliderBtn.centerX;
    self.minLineView.x = 0;
    
    self.maxLineView.width = self.width - self.rightSliderBtn.centerX;
    self.maxLineView.right = self.width;
    
    self.midLineView.width = self.rightSliderBtn.centerX - self.leftSliderBtn.centerX;
    self.midLineView.x = self.minLineView.right;
}

//根据滑块位置改变当前最小和最大的值
- (void)changeValueFromLocation {
    CGFloat contentWidth = self.width - self.marginCenterX * 2;
    self.curMinValue = (self.leftSliderBtn.centerX - self.marginCenterX)/contentWidth;
    self.curMaxValue = (self.rightSliderBtn.centerX - self.marginCenterX)/contentWidth;
}


- (UIButton *)leftSliderBtn {
    if (!_leftSliderBtn) {
        _leftSliderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _leftSliderBtn.size = CGSizeMake(28, 28);
        [_leftSliderBtn setImage:[UIImage imageNamed:@"in_icon_cut_orange"] forState:UIControlStateNormal];
        _leftSliderBtn.layer.cornerRadius = 14;
        _leftSliderBtn.layer.shadowOffset = CGSizeMake(0, 1);
        _leftSliderBtn.layer.shadowRadius = 5;
        _leftSliderBtn.layer.shadowOpacity = 0.15;
        _leftSliderBtn.userInteractionEnabled = false;
    }
    return _leftSliderBtn;
}

- (UIButton *)rightSliderBtn {
    if (!_rightSliderBtn) {
        _rightSliderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightSliderBtn.size = CGSizeMake(28, 28);
        [_rightSliderBtn setImage:[UIImage imageNamed:@"in_icon_cut_orange"] forState:UIControlStateNormal];
        _rightSliderBtn.layer.cornerRadius = 14;
        _rightSliderBtn.layer.shadowOffset = CGSizeMake(0, 1);
        _rightSliderBtn.layer.shadowRadius = 5;
        _rightSliderBtn.layer.shadowOpacity = 0.15;
        _rightSliderBtn.userInteractionEnabled = false;
    }
    return _rightSliderBtn;
}


@end

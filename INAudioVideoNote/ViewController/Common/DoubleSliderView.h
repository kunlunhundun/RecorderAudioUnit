//
//  DoubleSliderView.h
//  INAudioVideoNote
//
//  Created by kunlun on 06/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DoubleSliderView : UIView

@property (nonatomic, assign) CGFloat curMinValue;//当前最小的值
@property (nonatomic, assign) CGFloat curMaxValue;//当前最大的值
@property (nonatomic, assign) BOOL needAnimation;//是否需要动画
@property (nonatomic, assign) CGFloat minInterval;//间隔大小
@property (nonatomic, copy)  void (^sliderBtnChangePointBlock)(CGPoint leftPoint, CGPoint rightPoint);//滑块位置改变后的回调 leftPoint 左按钮的中心点的坐标 rightPoint右按钮的中心坐标

- (void)changeLocationFromValue;

@end

NS_ASSUME_NONNULL_END

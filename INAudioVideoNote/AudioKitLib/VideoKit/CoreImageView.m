//
//  CoreImageView.m
//  EAudioKit
//
//  Created by zhou on 15/11/18.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "CoreImageView.h"

@interface CoreImageView ()

@property (nonatomic, strong) CIContext * coreImageContext;
@property (nonatomic, strong) CIImage * image;

@end

@implementation CoreImageView

- (instancetype)initWithFrame:(CGRect)frame {
    EAGLContext * eaglContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self = [super initWithFrame:frame context:eaglContext];
    _coreImageContext = [CIContext contextWithEAGLContext:eaglContext];
    self.enableSetNeedsDisplay = NO;
    self.clipsToBounds = YES;
    self.userInteractionEnabled = NO;
    return self;
}

- (void)updateImage:(CIImage *)image {
    _image = image;
    [self display];
}

- (void)drawRect:(CGRect)rect {
    // 以像素为单位 Plus的点宽度x密度 ！= 像素
    CGFloat scale = [[UIScreen mainScreen]scale];
    if (scale == 3) {
        scale = 1080 / [UIScreen mainScreen].bounds.size.width;
    }
    CGRect destRect = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(scale, scale));
    CGRect fromRect = _image.extent;
    CGFloat dest_w  = destRect.size.width;
    CGFloat dest_h  = destRect.size.height;
    
    // 确保渲染到的View 宽高比和原始比例一致
    CGFloat ratio = fromRect.size.width / fromRect.size.height;
    if (dest_w / dest_h > ratio) { // 渲染的宽度超出比例 高度也要增加
        CGFloat increase_h = dest_w / ratio - dest_h;
        destRect = CGRectMake(0, -increase_h, dest_w, dest_w / ratio); // 顶端对齐
    }
    else { // 渲染的高度超出比例 宽度也要增加
        CGFloat increase_w = dest_h * ratio - dest_w;
        destRect = CGRectMake(0 - increase_w * 0.5, 0, dest_h * ratio, dest_h);
    }
    
    // 以左下角为(0,0) 向上y增加 向右x增加
    [_coreImageContext drawImage:_image inRect:destRect fromRect:fromRect];
}

@end

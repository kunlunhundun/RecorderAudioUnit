//
//  CoreImageView.h
//  EAudioKit
//
//  Created by zhou on 15/11/18.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface CoreImageView : GLKView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateImage:(CIImage *)image;

@end

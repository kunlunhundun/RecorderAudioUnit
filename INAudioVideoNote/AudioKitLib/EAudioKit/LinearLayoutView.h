//
//  LinearLayoutView.h
//  EAudioKit
//
//  Created by cybercall on 15/8/4.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,LinearLayoutDir)
{
    LinearLayoutHor,
    LinearLayoutVer
    
};

typedef NS_ENUM(NSInteger,LinearLayoutSubDir)
{
    LinearLayoutLeft,
    LinearLayoutRight,
    LinearLayoutTop,
    LinearLayoutBottom
    
};


@interface LinearLayoutView : UIView


@property (nonatomic,assign) CGRect layoutRect;
@property (nonatomic,readonly) CGRect layoutFitRect;

@property (nonatomic,readonly) LinearLayoutDir layoutDir;
@property (nonatomic,assign)   BOOL     autoGrow;
@property (nonatomic,assign)   int      width;
@property (nonatomic,assign)   int      height;

-(void)config:(CGRect)layoutRect LinearLayoutDir:(LinearLayoutDir)dir;


-(void)addLayoutView:(UIView*)view;
-(void)addLayoutView:(UIView*)view withPadding:(int)padding;
-(void)addLayoutPadding:(int)padding;
-(void)addLayoutView:(UIView*)view withPadding:(int)padding subDir:(LinearLayoutSubDir)subDir;
-(void)addLayoutViewFlex:(UIView*)view;

@end





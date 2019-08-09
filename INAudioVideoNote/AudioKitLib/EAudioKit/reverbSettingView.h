//
//  reverbSettingView.h
//  letSing
//
//  Created by cybercall on 15/8/3.
//  Copyright © 2015年 rcshow. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol ReverbParamDelegate <NSObject>

-(int)getReverbParamValue:(int)idx;

-(void)setReverbParamValue:(int)idx Value:(int)value;

@end

@interface ReverbParamSettingView : UIView

-(void)setReverbParamChangedDelegate:(id<ReverbParamDelegate>)delegate;

-(void)updateUI;

+(instancetype) createReverbParamSettingView;

@end



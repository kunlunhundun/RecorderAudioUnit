//
//  reverbSettingView.m
//  letSing
//
//  Created by cybercall on 15/8/3.
//  Copyright © 2015年 rcshow. All rights reserved.
//


#import "EAudioKit/EAudioKit.h"
#import "LinearLayoutView.h"


#define TAG_SLIDER_INDEX 100
#define TAG_INPUT_INDEX  200
#define TAG_BUTTON_INDEX 300

@interface ReverbParamSettingView()
{
    id<ReverbParamDelegate> _delegate;
}
@end

@implementation ReverbParamSettingView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+(instancetype) createReverbParamSettingView
{
    CGRect zeorRect = CGRectMake(0, 0, 0, 0);
    ReverbParamSettingView* SELF = [[ReverbParamSettingView alloc ] initWithFrame:zeorRect];
    
    NSArray* arrays = @[
                        @{@"text":@"RSFACTOR",      @"x" : @20,     @"y":@600},
                        @{@"text":@"WIDTH",         @"x" : @-100,   @"y":@100},
                        @{@"text":@"DRY",           @"x" : @-6000,  @"y":@1000},
                        @{@"text":@"WET",           @"x" : @-6000,  @"y":@1000},
                        @{@"text":@"PREDELAY",      @"x" : @-20000, @"y":@20000},
                        @{@"text":@"RT60",          @"x" : @0,      @"y":@2000},
                        @{@"text":@"IDIFFUSION1",   @"x" : @0,      @"y":@100},
                        @{@"text":@"IDIFFUSION2",   @"x" : @0,      @"y":@100},
                        @{@"text":@"DIFFUSION1",    @"x" : @0,      @"y":@100},
                        @{@"text":@"DIFFUSION2",    @"x" : @0,      @"y":@100},
                        @{@"text":@"INPUTDAMP",     @"x" : @0,      @"y":@2000000},
                        @{@"text":@"DAMP",          @"x" : @0,      @"y":@1000000},
                        @{@"text":@"OUTPUTDAMP",    @"x" : @0,      @"y":@2000000},
                        @{@"text":@"SPIN",          @"x" : @0,      @"y":@1000},
                        @{@"text":@"SPINDIFF",      @"x" : @0,      @"y":@100},
                        @{@"text":@"SPINLIMIT",     @"x" : @0,      @"y":@20},
                        @{@"text":@"WANDER",        @"x" : @0,      @"y":@100},
                        @{@"text":@"DCCUTFREQ",     @"x" : @0,      @"y":@10000},
                       ];
    
    int count = arrays.count;
    int padding = 1;
    const int btnSize = 30;
    int SCREEN_WIDTH = [[UIScreen mainScreen] bounds].size.width;
    int SCREEN_HEIGHT = [[UIScreen mainScreen] bounds].size.height;
    CGRect rect = CGRectMake(0, 10, SCREEN_WIDTH, 0);
    LinearLayoutView* linearView = [[LinearLayoutView alloc ] initWithFrame:rect];
    [linearView config:rect LinearLayoutDir:LinearLayoutHor];
    linearView.autoGrow = YES;
    
    for (int i=0; i < count; i++) {
        NSDictionary* dict =  [arrays objectAtIndex:i];
        NSString* lableTxt = [dict valueForKey:@"text"];
        NSNumber* x = [dict valueForKey:@"x"];
        NSNumber* y = [dict valueForKey:@"y"];
        
        [linearView addLayoutView:nil withPadding:2 subDir:LinearLayoutRight];
        
        UILabel* lable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, btnSize)];
        lable.text = lableTxt;
        lable.textAlignment = NSTextAlignmentRight;
        [linearView addLayoutView:lable withPadding:padding];
        
        UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn1.frame = CGRectMake(0, 0, btnSize, btnSize);
        btn1.tag = TAG_BUTTON_INDEX + i;
        [btn1 setBackgroundColor:[UIColor redColor]];
        [btn1 setTitle:@"-" forState:UIControlStateNormal];
        [btn1 addTarget:SELF action:@selector(onBtnMinu:) forControlEvents:UIControlEventTouchDown];
        [linearView addLayoutView:btn1 withPadding:padding];
        
        UITextField* textValue = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
        textValue.borderStyle = UITextBorderStyleRoundedRect;
        textValue.font = [UIFont systemFontOfSize:7];
        textValue.enabled = NO;
        textValue.tag = TAG_INPUT_INDEX + i;
        [linearView addLayoutView:textValue withPadding:padding subDir:LinearLayoutRight];
        
        
        UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn2.frame = CGRectMake(0, 0, btnSize, btnSize);
        btn2.tag = TAG_BUTTON_INDEX + i;
        btn2.backgroundColor = [UIColor blueColor];
        [btn2 setTitle:@"+" forState:UIControlStateNormal];
        [btn2 addTarget:SELF action:@selector(onBtnAdd:) forControlEvents:UIControlEventTouchDown];
        [linearView addLayoutView:btn2 withPadding:0 subDir:LinearLayoutRight];
        
        
        UISlider* slider = [[UISlider alloc ] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/3 , 25)];
        slider.minimumValue = x.intValue;
        slider.maximumValue = y.intValue;
        slider.enabled = YES;
        slider.userInteractionEnabled = YES;
        slider.tag = TAG_SLIDER_INDEX + i;
        [slider addTarget:SELF action:@selector(onSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [linearView addLayoutViewFlex:slider];
        
        CGRect newRect = linearView.layoutFitRect;
        newRect.size.width = SCREEN_WIDTH;
        newRect.origin.y += newRect.size.height + 5;
        newRect.size.height = 0;
        linearView.layoutRect = newRect;
    }

    UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnClose.frame = CGRectMake(10, linearView.layoutRect.origin.y + 4, 50, 40);
    [btnClose setTitle:@"Close" forState:UIControlStateNormal];
    [btnClose addTarget:SELF action:@selector(onCloseBtn:) forControlEvents:UIControlEventTouchDown];
    [linearView addSubview:btnClose];
    
    SELF.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:SELF.frame];
    CGSize contentSize = linearView.frame.size;
    scrollView.contentSize = contentSize;
    [scrollView addSubview:linearView];
    [SELF addSubview:scrollView];
    SELF.backgroundColor = [UIColor whiteColor];
    return SELF;
}

-(void)setReverbParamChangedDelegate:(id<ReverbParamDelegate>)delegate
{
    _delegate = delegate;
}


-(void)updateUI
{
    if (_delegate == nil) {
        return;
    }
    
    for (int i=0; i < AuraReverbOption_MAX; i++) {
        int v = [_delegate getReverbParamValue:i];
        [self updateUI:i Value:v];
    }
}

- (void)onCloseBtn:(UIButton*)sender {
    self.hidden = YES;
}

- (void)onSliderChanged:(UISlider*)sender
{
    [self updateSliderToInputField:sender];
}

- (void)onBtnAdd:(UIButton*)sender
{
    int idx = sender.tag - TAG_BUTTON_INDEX;
    UISlider* slider = [self viewWithTag:(TAG_SLIDER_INDEX + idx)];
    slider.value = slider.value + 1;
    [self updateSliderToInputField:slider];
}

- (void)onBtnMinu:(UIButton*)sender
{
    int idx = sender.tag - TAG_BUTTON_INDEX;
    UISlider* slider = [self viewWithTag:(TAG_SLIDER_INDEX + idx)];
    slider.value = slider.value - 1;
    [self updateSliderToInputField:slider];
}


-(void)updateSliderToInputField:(UISlider*)slider
{
    NSInteger t = [slider tag] - TAG_SLIDER_INDEX + TAG_INPUT_INDEX;
    UITextField* textField = [self viewWithTag:t];
    if (textField != nil) {
        textField.text = [NSString stringWithFormat:@"%d", (int)slider.value ];
    }
    if (_delegate) {
        int idx = slider.tag - TAG_SLIDER_INDEX ;
        [_delegate setReverbParamValue:idx Value:slider.value];
    }
    
}

-(void)updateUI:(int)EQ Value:(int)v
{
    UISlider* slider = [self viewWithTag:(EQ + TAG_SLIDER_INDEX)];
    if (slider != nil) {
        slider.value = v;
        [self updateSliderToInputField:slider];
    }

}

@end

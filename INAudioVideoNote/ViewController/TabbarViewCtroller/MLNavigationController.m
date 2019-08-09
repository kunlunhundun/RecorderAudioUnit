//
//  MLNavigationController.m
//  MLinkTeacher
//
//  Created by kunlun on 17/4/9.
//  Copyright © 2017年 MLink. All rights reserved.
//

#import "MLNavigationController.h"
#import "INConst.h"

@interface MLNavigationController ()<UINavigationControllerDelegate,UIGestureRecognizerDelegate>

@end

@implementation MLNavigationController



+ (void)initialize{
    // 1.取出设置主题的对象
    UINavigationBar *navBar = [UINavigationBar appearance];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [UIApplication sharedApplication].statusBarStyle = UIBarStyleBlack;
    //self.navigationController.navigationBar.barStyle = UIBarStyleBlack
    
    if([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        navBar.translucent = NO;
      //  navBar.translucent = YES;
    }
    
//    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
//    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
//        statusBar.backgroundColor = [UIColor bg_whiteColor];
//    }  //设置状态栏的颜色
    
    [navBar setBarTintColor:UIColorFromRGB(0x2E2D38)];  //
    [navBar setTitleTextAttributes:@{
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSFontAttributeName:[UIFont fontWithName:@"Helvetica-Bold" size:18]
                                     }];
    
    [navBar setTintColor:[UIColor whiteColor]];
    
    
    UIBarButtonItem *appearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
    //设置导航栏的字体包括backBarButton和leftBarButton，rightBarButton的字体
    NSDictionary *textAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16],
                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                     };
    
    [appearance setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
//    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setBackgroundVerticalPositionAdjustment:10 forBarMetrics:UIBarMetricsDefault];
//    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setBackButtonBackgroundVerticalPositionAdjustment:10 forBarMetrics:UIBarMetricsDefault];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    
    [[UINavigationBar appearance]  setBackgroundImage:[[UIImage alloc] init] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
   // navBar.clipsToBounds = YES;
}


//- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
//    if (self.viewControllers.count > 0) {
//        viewController.hidesBottomBarWhenPushed = YES;
//    }
//    [super pushViewController:viewController animated:animated];
//}



- (void)viewDidLoad
{
    
    __weak MLNavigationController *weakSelf = self;
    
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
    {
        self.interactivePopGestureRecognizer.delegate = weakSelf;
        
        self.delegate = weakSelf;
    }
    
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
    if ( [self respondsToSelector:@selector(interactivePopGestureRecognizer)]   == YES )
    {
       // self.interactivePopGestureRecognizer.enabled = NO;
    }
    
    if (self.viewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    
    [super pushViewController:viewController animated:animated];
    
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    //只有一个控制器的时候禁止手势，防止卡死现象
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    if (self.childViewControllers.count > 1) {
        if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            self.interactivePopGestureRecognizer.enabled = YES;
        }
    }
    return YES;
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    //只有一个控制器的时候禁止手势，防止卡死现象
    if (self.childViewControllers.count == 1) {
        if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            self.interactivePopGestureRecognizer.enabled = NO;
        }
    }
}







@end

//
//  MLBaseViewController.m
//  MLinkTeacher
//
//  Created by kunlun on 17/4/15.
//  Copyright © 2017年 MLink. All rights reserved.
//

#import "MLBaseViewController.h"

@interface MLBaseViewController ()

@end

@implementation MLBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}


-(void)SetNavigation_title:(NSString*)navigation_title{
    
    self.navigationItem.title = navigation_title;
}


-(void)creatLeftBackBtn:(SEL)action{
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *norImage = [UIImage imageNamed:@""];
    UIImage *heiImage = [UIImage imageNamed:@""];
    [button setImage:norImage forState:UIControlStateNormal];
    [button setImage:heiImage forState:UIControlStateHighlighted];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    UIView *barButtonView = [[UIView alloc] initWithFrame:button.bounds];
    [barButtonView addSubview:button];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:barButtonView];
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

-(void)creatRightBtn:(SEL)action{
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *norImage = [UIImage imageNamed:@""];
    UIImage *heiImage = [UIImage imageNamed:@""];
    [button setImage:norImage forState:UIControlStateNormal];
    [button setImage:heiImage forState:UIControlStateHighlighted];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    UIView *barButtonView = [[UIView alloc] initWithFrame:button.bounds];
    [barButtonView addSubview:button];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:barButtonView];
    
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

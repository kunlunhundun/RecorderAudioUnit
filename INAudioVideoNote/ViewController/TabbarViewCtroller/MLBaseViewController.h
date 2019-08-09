//
//  MLBaseViewController.h
//  MLinkTeacher
//
//  Created by kunlun on 17/4/15.
//  Copyright © 2017年 MLink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MLBaseViewController : UIViewController


@property(nonatomic,strong) NSString *navigation_title;

-(void)creatLeftBackBtn:(SEL)action;

-(void)creatRightBtn:(SEL)action;


@end

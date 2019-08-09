//
//  MLTabbarViewCtroller.m
//  MLinkTeacher
//
//  Created by kunlun on 17/4/8.
//  Copyright © 2017年 MLink. All rights reserved.
//

#import "MLTabBarViewCtroller.h"
#import "MLNavigationController.h"
#import "RecordMainViewController.h"
#import "INConst.h"

@interface MLTabBarViewCtroller ()<UITabBarControllerDelegate>

@property (nonatomic, strong) UINavigationController *homeNav;
@property (nonatomic, strong) UINavigationController *messageNav;

@property (strong,nonatomic) NSMutableArray *fixTabButtons;

@end

@implementation MLTabBarViewCtroller

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupTabBar];
    [self setupControllers];
    
}

//BackArrow

- (void)setupTabBar{
    self.fixTabButtons = [NSMutableArray array];
    
    UIStackView *sView = [[UIStackView alloc]initWithFrame:CGRectMake(0, self.tabBar.frame.origin.y-IPHONEX_EXTRA_HEIGHT, IN_IPHONE_WIDTH, 49)];//addArrangedSubview
    sView.axis = UILayoutConstraintAxisHorizontal;
    sView.distribution = UIStackViewDistributionFillEqually;
    sView.spacing = 0;
    sView.alignment = UIStackViewAlignmentFill;
    sView.backgroundColor = [UIColor whiteColor];
    [self.view insertSubview:sView aboveSubview:self.tabBar];
    NSArray *nomarlImgs = @[@"nav_game",@"nav_vip",@"nav_explore",@"nav_my"];
    NSArray *selectImgs = @[@"nav_game_s",@"nav_vip_s",@"nav_explore_s",@"nav_my_s"];
    NSArray *titles = @[@"游戏",@"VIP",@"发现",@"我的"];
    for (int i=0; i<4; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:11.0f];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
        [btn setTitleColor:UIColorFromRGB(0x666666) forState:UIControlStateSelected];
        [btn setImage:[UIImage imageNamed:nomarlImgs[i]] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:selectImgs[i]] forState:UIControlStateSelected];
        [sView addArrangedSubview:btn];
        [btn addTarget:self action:@selector(btnTap:) forControlEvents:UIControlEventTouchUpInside];
        btn.backgroundColor = [UIColor whiteColor];
        
        CGFloat titleWidth = btn.titleLabel.intrinsicContentSize.width;
        CGFloat imageWidth = btn.imageView.bounds.size.width;
        CGFloat titleHeight = btn.titleLabel.intrinsicContentSize.height;
        CGFloat imageHeight = btn.imageView.bounds.size.height;
        btn.imageEdgeInsets = UIEdgeInsetsMake(-titleHeight/2-imageHeight/2-3, titleWidth/2+imageWidth/2, titleHeight/2+imageHeight/2+3,-titleWidth/2-imageWidth/2);
        btn.titleEdgeInsets = UIEdgeInsetsMake(titleHeight/2+imageHeight/2+5, -imageWidth/2-titleWidth/2-1.5, -titleHeight/2-imageHeight/2-5,imageWidth/2+titleWidth/2+1.5);
        
        btn.tag = i;
        if (i==0) {
            btn.selected = YES;
        }
        [self.fixTabButtons addObject:btn];
    }
    
    UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, -0.5, IN_IPHONE_WIDTH, 0.5)];
    line.backgroundColor = [UIColor blackColor];
    line.alpha = 0.3;
    [sView addSubview:line];
    
    UIView *whiteBg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, IN_IPHONE_WIDTH, 100)];
    whiteBg.backgroundColor = [UIColor whiteColor];
    [sView insertSubview:whiteBg atIndex:0];
    //遮住下面额外透明部分
    self.fixTabbar = sView;
}
- (void)btnTap:(UIButton*)btn{
    self.selectedIndex = btn.tag;
    for (UIButton *inBtn in self.fixTabButtons) {
        inBtn.selected = inBtn.tag == btn.tag;
    }
}

- (void)setupControllers{
    
    UINavigationController *homeNav = [self navigationControllerWithController:[RecordMainViewController class]
                                                                   tabBarTitle:@"游戏"
                                                                   normalImage:[UIImage imageNamed:@"nav_game"]
                                                                 selectedImage:[UIImage imageNamed:@"nav_game_s"]];
 
   
    UINavigationController *mineNav = [self navigationControllerWithController:[RecordMainViewController class]
                                                                   tabBarTitle:@"我的"
                                                                   normalImage:[UIImage imageNamed:@"nav_my"]
                                                                 selectedImage:[UIImage imageNamed:@"nav_my_s"]];
 
    
    /**
     *  设置tabbar的字体颜色
     */
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:UIColorFromRGB(0x333333), NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica" size:11.0f],NSFontAttributeName,nil] forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:UIColorFromRGB(0x666666), NSForegroundColorAttributeName,[UIFont fontWithName:@"Helvetica" size:11.0f],NSFontAttributeName, nil] forState:UIControlStateSelected];
    self.homeNav = homeNav;

    self.viewControllers = @[homeNav,mineNav];
    self.delegate = self;

}
- (UINavigationController *)navigationControllerWithController:(Class)controller tabBarTitle:(NSString *)tabBarTitle normalImage:(UIImage *)normalImage selectedImage:(UIImage *)selectedImage{
    UIViewController *vc = [[controller alloc] init];;
    
    UITabBarItem *item = [[UITabBarItem alloc]
                          initWithTitle:tabBarTitle
                          image:normalImage
                          selectedImage:selectedImage];


    item.imageInsets = UIEdgeInsetsMake(-3, 0, 3, 0);
    item.titlePositionAdjustment = UIOffsetMake(0, -5);
    item.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item.selectedImage = [item.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    vc.tabBarItem = item;
    vc.tabBarItem.title = tabBarTitle;

    MLNavigationController *nav = [[MLNavigationController alloc] initWithRootViewController:vc];
    return nav;
}
- (void)setSelectedIndex:(NSUInteger)selectedIndex{
    [super setSelectedIndex:selectedIndex];
    
    for (UIButton *btn in self.fixTabButtons) {
        if (btn.tag == selectedIndex) {
            btn.selected = YES;
        }else{
            btn.selected = NO;
        }
    }
}
#pragma mark  UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    for (UIButton *btn in self.fixTabButtons) {
        if (btn.tag == tabBarController.selectedIndex) {
            btn.selected = YES;
        }else{
            btn.selected = NO;
        }
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    UINavigationController *nav = (UINavigationController *)viewController;
    NSInteger index = [tabBarController.viewControllers indexOfObject:viewController];
  
    return YES;
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

//
//  AppDelegate.m
//  INAudioVideoNote
//
//  Created by kunlun on 24/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "AppDelegate.h"
#import "MLTabBarViewCtroller.h"
#import "RecordMainViewController.h"
#import "MLNavigationController.h"

@interface AppDelegate ()

@property (strong, nonatomic) MLTabBarViewCtroller *mlTabBarViewCtrl;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];

    [self creatTabBarVC];
    
    return YES;
}


- (void)creatTabBarVC{
   // _mlTabBarViewCtrl = [[MLTabBarViewCtroller alloc]init];
    [UINavigationBar appearance].translucent = NO;
    RecordMainViewController *mainViewCtroller = [[RecordMainViewController alloc]init];
    MLNavigationController *navigationVC = [[MLNavigationController alloc] initWithRootViewController:mainViewCtroller];
    self.window.rootViewController = navigationVC;

    [self.window makeKeyAndVisible];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end

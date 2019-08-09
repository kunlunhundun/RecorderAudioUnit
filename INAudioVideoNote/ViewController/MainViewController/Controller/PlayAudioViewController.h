//
//  PlayAudioViewController.h
//  INAudioVideoNote
//
//  Created by kunlun on 27/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlayAudioViewController : UIViewController

@property(nonatomic,strong) NSString *fileName;
@property(nonatomic,strong) AudioInfoModel *infoModel;

@end

NS_ASSUME_NONNULL_END

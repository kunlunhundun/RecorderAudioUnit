//
//  ConvertPopView.h
//  INAudioVideoNote
//
//  Created by kunlun on 12/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SelectPopTitleIndexBlock)(NSString *title);


@interface ConvertPopView : UIView

+(void)showSelectTitle:(NSString*)title  titleIndexBlock:(SelectPopTitleIndexBlock)selectTitleBlock;


@end

NS_ASSUME_NONNULL_END

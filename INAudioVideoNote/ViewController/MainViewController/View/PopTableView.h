//
//  PopTableView.h
//  INAudioVideoNote
//
//  Created by kunlun on 31/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SelectTitleIndexBlock)(NSString *title);

@interface PopTableView : UIView



+(void)showSelectTitleIndexBlock:(SelectTitleIndexBlock)selectTitleBlock;


@end

NS_ASSUME_NONNULL_END

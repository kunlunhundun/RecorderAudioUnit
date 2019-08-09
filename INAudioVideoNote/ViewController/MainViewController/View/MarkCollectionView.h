//
//  MarkCollectionView.h
//  INAudioVideoNote
//
//  Created by kunlun on 07/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MarkCollectionView : UIView

@property(nonatomic,copy) void (^markTimeSelectIndexBlock)(NSIndexPath *indexPath, NSInteger markTime);

@property(nonatomic,assign) BOOL ishowCloseImg;
-(void)updateDataArr:(NSArray*)dataArr;

@end

NS_ASSUME_NONNULL_END

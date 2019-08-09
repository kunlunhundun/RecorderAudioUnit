//
//  RecordListView.h
//  INAudioVideoNote
//
//  Created by kunlun on 26/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SelectTableViewIndexBlock)(NSInteger indexRow);
@class RecordListViewController;

@interface RecordListView : UIView

@property(nonatomic,weak) RecordListViewController *weakController;
@property(nonatomic,copy) SelectTableViewIndexBlock selectTableViewIndexBlock;

-(void)updateTableViewData:(NSArray*)dataArr;
-(void)updateWithEdit:(BOOL)isEdit;

@end

NS_ASSUME_NONNULL_END

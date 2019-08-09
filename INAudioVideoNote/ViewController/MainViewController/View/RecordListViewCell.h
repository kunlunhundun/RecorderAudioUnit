//
//  RecordListViewCell.h
//  INAudioVideoNote
//
//  Created by kunlun on 26/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomImgLabBtn.h"

typedef void (^TableViewCellTouchUpInsideBlock)(NSIndexPath *indexPath, int tag);
NS_ASSUME_NONNULL_BEGIN

@interface RecordListViewCell : UITableViewCell

@property(nonatomic, strong) UILabel *nameLab;
@property(nonatomic, strong) UILabel *timeLab;
@property(nonatomic, strong) UILabel *dateTimeLab;
@property(nonatomic, strong) CustomImgLabBtn *renameBtn;
@property(nonatomic, strong) CustomImgLabBtn *deleteBtn;
@property(nonatomic,strong) NSIndexPath *indexPath;

@property(nonatomic,copy) TableViewCellTouchUpInsideBlock tableViewCellTouchUpInsideBlock;

@end

NS_ASSUME_NONNULL_END

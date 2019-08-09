//
//  MarkCollectionViewCell.h
//  INAudioVideoNote
//
//  Created by kunlun on 07/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MarkCollectionViewCell : UICollectionViewCell

@property(nonatomic,strong) UILabel *timeLab;
@property(nonatomic,strong) UILabel *numLab;
@property(nonatomic,strong) UIImageView *closeImgView;
@end

NS_ASSUME_NONNULL_END

//
//  MarkCollectionView.m
//  INAudioVideoNote
//
//  Created by kunlun on 07/08/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "MarkCollectionView.h"
#import <Masonry/Masonry.h>
#import "MarkCollectionViewCell.h"


@interface MarkCollectionView()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property(nonatomic,strong) UICollectionView *collectionView;
@property(nonatomic,strong) NSArray *dataArr;

@end


@implementation MarkCollectionView

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

-(void)setupView{

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 15;
    layout.minimumInteritemSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(0, 15, 0, 15);
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    [self addSubview:collectionView];
    [collectionView registerClass:[MarkCollectionViewCell class] forCellWithReuseIdentifier:@"MarkCollectionViewCell"];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    _collectionView = collectionView;

}

-(void)updateDataArr:(NSArray*)dataArr{
    _dataArr = dataArr;
    [self.collectionView reloadData];
}

-(void)formatterTime:(NSInteger)timeCount timeLab:(UILabel*)timeLab{
    NSInteger minutes = timeCount / 60;
    NSInteger seconds =  timeCount % 60;
    NSInteger hours = minutes / 60;
    minutes = minutes % 60;
    NSString *secondStr = seconds < 10 ? [NSString stringWithFormat:@"0%ld",seconds] : [NSString stringWithFormat:@"%ld",seconds];
    NSString *minuteStr = minutes < 10 ? [NSString stringWithFormat:@"0%ld",minutes] : [NSString stringWithFormat:@"%ld",minutes];
    NSString *hourStr = hours < 10 ? [NSString stringWithFormat:@"0%ld",hours] : [NSString stringWithFormat:@"%ld",hours];
    timeLab.text  = [NSString stringWithFormat:@"%@:%@:%@",hourStr,minuteStr,secondStr];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
   
    return _dataArr.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    return _ishowCloseImg ? CGSizeMake(110, 110) : CGSizeMake(80, 80);
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"MarkCollectionViewCell";
    MarkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSString *markStr = self.dataArr[indexPath.row];
    NSInteger markTime = [markStr integerValue];
    [self formatterTime:markTime timeLab:cell.timeLab];
    cell.numLab.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    cell.closeImgView.hidden = !_ishowCloseImg;
    return cell;
}



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (_markTimeSelectIndexBlock) {
        NSString *markStr = self.dataArr[indexPath.row];
        _markTimeSelectIndexBlock(indexPath, [ markStr integerValue] );
    }
}

@end

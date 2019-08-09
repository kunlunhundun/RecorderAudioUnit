//
//  AudioInfoModel.h
//  INAudioVideoNote
//
//  Created by kunlun on 30/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseArchiverModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioInfoModel : BaseArchiverModel

@property(nonatomic,copy) NSString *dateTime;
@property(nonatomic,copy) NSString *fileName;
@property(nonatomic,copy) NSString *markTime;
@property(nonatomic,copy) NSString *durationTime;


@end

NS_ASSUME_NONNULL_END

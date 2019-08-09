//
//  FilePathManager.h
//  INAudioVideoNote
//
//  Created by kunlun on 24/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FilePathManager : NSObject

    
+(NSString *)getAudioFileRecordPath;
+(UInt64)getFileSize:(NSString *)fileName;
+(NSArray*)getAllVoicePathName;
+(BOOL)changeFileName:(NSString*)originalFileName newFileName:(NSString *)newFileName;
+(void)deleteFileName:(NSString*)fileName;
+(NSTimeInterval)getAudiodurationTimer:(NSString*)fileName;
+(void)saveArchiverModel:(NSObject*)archiverModel;
+(NSArray*)getArchiverModel;
+(void)updateArchiverModel:(NSMutableArray *)dataArr;

@end

NS_ASSUME_NONNULL_END

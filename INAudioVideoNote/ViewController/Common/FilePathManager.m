//
//  FilePathManager.m
//  INAudioVideoNote
//
//  Created by kunlun on 24/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "FilePathManager.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioInfoModel.h"

#define Archiver_AudioData @"ArchiverAudioData"

@implementation FilePathManager

+(NSString *)getAudioFileRecordPath {
    
    NSString *directoryPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(),@"/Documents/RecordVoice/" ];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath ] == false) {
       BOOL isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:true attributes:nil error:nil];
        if (isSuccess == false) {
            NSLog(@"createAudioFileRecordPath failed");
        }
    }
    
    return directoryPath;
}

+(NSString *)getAudioFileInfoPath {
    
    NSString *directoryPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(),@"/Documents/RecordInfo/" ];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath ] == false) {
        BOOL isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:true attributes:nil error:nil];
        if (isSuccess == false) {
            NSLog(@"createAudioFileRecordPath failed");
        }
    }
    
    return directoryPath;
}

+(UInt64)getFileSize:(NSString *)fileName{
    if(fileName.length < 1) {
        return 0;
    }
    UInt64 size = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName ] ) {
        NSDictionary *attrDic = [[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil];
        if ([attrDic isKindOfClass: [NSDictionary class]]){
            size += attrDic.fileSize ;
        }
    }
    return size/1024;
}

+(NSArray*)getAllVoicePathName{
    NSMutableArray *fileNameArr = [[NSMutableArray alloc]initWithCapacity:1];
    NSString *directPath = [self getAudioFileRecordPath];
    if (directPath == nil) {
        return fileNameArr;
    }
    BOOL isDir = false;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:directPath isDirectory:&isDir];
    if (isExist) {
        if (isDir) {
            NSArray *fileArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directPath error:nil];
            for (NSString *fileName in fileArr) {
                if ([fileName hasSuffix:@"mp3"] || [fileName hasSuffix:@"m4a"] || [fileName hasSuffix:@"wav"] ||[fileName hasSuffix:@"pcm"]) {
                    [fileNameArr addObject:fileName];
                }
            }
        }
    }
    return fileNameArr;
}


+(BOOL)changeFileName:(NSString*)originalFileName newFileName:(NSString *)newFileName {
    BOOL isSuccess = [[NSFileManager defaultManager] moveItemAtPath:originalFileName toPath:newFileName error:nil];
    return isSuccess;
}

+(void)deleteFileName:(NSString*)fileName{
    if (fileName.length < 1) {
        return ;
    }
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:fileName];
    if (isExist) {
        [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
    }
}


+(NSTimeInterval)getAudiodurationTimer:(NSString*)fileName{
    
    NSString *directPath = [self getAudioFileRecordPath];
    if (directPath == nil) {
        return 0;
    }
    NSString *filePathName = [NSString stringWithFormat:@"%@%@",directPath,fileName];
    AVAudioSession *audioSession = [[AVAudioSession alloc]init];
    [audioSession setActive:YES error:nil];
    
    NSURL *url = [NSURL fileURLWithPath:filePathName];
    AVAudioPlayer *player =  [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
    NSTimeInterval duration = player.duration;
    player = nil;
    return duration ;
}


+(void)saveArchiverModel:(NSObject*)archiverModel{
    
    NSString *filePath = [NSString stringWithFormat:@"%@%@",[self getAudioFileInfoPath],Archiver_AudioData] ;
    NSArray *modelArr = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    if (modelArr == nil) {
        [NSKeyedArchiver archiveRootObject:[NSArray arrayWithObject:archiverModel] toFile:filePath];
    }else{
        NSMutableArray *dataArr = [NSMutableArray arrayWithArray:modelArr];
        [dataArr insertObject:archiverModel atIndex:0];
        [NSKeyedArchiver archiveRootObject:dataArr toFile:filePath];
    }
}

+(NSArray*)getArchiverModel{
    NSString *filePath = [NSString stringWithFormat:@"%@%@",[self getAudioFileInfoPath],Archiver_AudioData] ;
    NSArray *dataArr = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    return dataArr;
}

+(void)updateArchiverModel:(NSMutableArray *)dataArr{
    NSString *filePath = [NSString stringWithFormat:@"%@%@",[self getAudioFileInfoPath],Archiver_AudioData] ;
    if (dataArr){
        [NSKeyedArchiver archiveRootObject:dataArr toFile:filePath];
    }
}
    
    
@end

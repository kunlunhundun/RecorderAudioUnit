//
//  IN_FilePathManager.swift
//  INAudioVideo
//
//  Created by kunlun on 23/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

import UIKit

class IN_FilePathManager: NSObject {

    static func getAudioFileRecordPath() -> String? {
        var directoryPath = NSHomeDirectory() + "/Documents/RecordVoice/"
        if FileManager.default.fileExists(atPath: directoryPath) == false {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            }catch {
                NSLog("文件夹创建失败\n")
               return nil
            }
        }
        return directoryPath
    }
    
    static func getFileSize(fileName:String) -> UInt64{
        guard fileName.count > 0 else {
            return 0
        }
        var size:UInt64 = 0
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: fileName) {
            do {
                let attr = try fileMgr.attributesOfItem(atPath: fileName)
                let dict = attr as NSDictionary
                size += dict.fileSize()
            }catch {
                
            }
        }
        return size
    }
    
    static func deleteFileName(fileName:String?){
        guard  fileName != nil || fileName != "" else {
           return
        }
        do {
            let manager = FileManager.default
            if manager.fileExists(atPath: fileName!) {
                try manager.removeItem(atPath: fileName!)
            }
        }catch {
            
        }
    }
    
    static func getAllVoicePathName() -> [String]{
        var fileNameArr : [String] = []
        let fileManager = FileManager.default
        let directPath = self.getAudioFileRecordPath()
        guard let voiceDirectPath = directPath else {
            return fileNameArr
        }
        var isDir:ObjCBool = false
        let isExist = fileManager.fileExists(atPath: voiceDirectPath, isDirectory: &isDir)
        if isExist {
            if isDir.boolValue {
                do {
                    let fileArr = try fileManager.contentsOfDirectory(atPath: voiceDirectPath)
                    for fileName in fileArr {
                        if ( fileName.hasSuffix(".mp3") || fileName.hasSuffix(".m4a") || fileName.hasSuffix(".pcm")){
                            fileNameArr.append(fileName)
                        }
                    }
                }catch {
                    
                }
              
            }
        }
        return fileNameArr
    }
    static func changFileName(newFileName:String,originalFileName:String) -> Bool {
        
        let manager = FileManager.default
       
        do {
            try manager.moveItem(atPath: originalFileName, toPath: newFileName)
        } catch  {
            NSLog("setNewFileName is failed")
            return false
        }
        return true
    }
    
    
}

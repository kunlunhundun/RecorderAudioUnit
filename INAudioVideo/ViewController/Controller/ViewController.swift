//
//  ViewController.swift
//  INAudioVideo
//
//  Created by kunlun on 22/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

import UIKit;
import EAudioKit

class ViewController: UIViewController {

    var micSpot:EAudioSpot!
    var audioGraph:EAudioGraph!
    var isPause:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func initView(){
        
        let recordBtn = UIButton.init(frame: .zero)
        recordBtn.backgroundColor = UIColor.red
        self.view.addSubview(recordBtn)
        recordBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-130)
            make.width.height.equalTo(60)
        }
        recordBtn.addTarget(self, action: #selector(recordStart), for: .touchUpInside)
    }
    
    @objc func recordStart(){
        if audioGraph == nil {
            initAudio()
        }else{
            isPause ?  resumeRecordAudio() : pauseRecordAudio()
        }
    }
    
    func initAudio(){
         audioGraph = EAudioGraph.init(name: "audioStudio", with: .realTime)
         micSpot = audioGraph.createMicAudioSpot("micPlayer")
        let directPath = IN_FilePathManager.getAudioFileRecordPath()
        guard let voiceDirectPath = directPath  else {
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddhh:mm:ss"
        let localSaveDate = formatter.string(from: NSDate() as Date)
        let voiceRecordName = voiceDirectPath + localSaveDate + ".pcm"
        audioGraph.startRecord(voiceRecordName)
    }
    
    func pauseRecordAudio(){
        audioGraph.stopGraph()
        isPause = true
    }
    func resumeRecordAudio(){
        audioGraph.startGraph()
        isPause = false
    }
    
    func stopRecordAudio(){
        audioGraph.stopRecord()
        audioGraph.stopGraph()
        micSpot = nil
        audioGraph = nil
    }
    
    func saveRecordAudio(fileName:String){
        

    }
    
    



}


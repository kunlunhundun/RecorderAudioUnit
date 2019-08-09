//
//  HistoryAudioRecordViewController.swift
//  INAudioVideo
//
//  Created by kunlun on 23/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

import UIKit
import SnapKit
import XCGLogger

class HistoryAudioRecordViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let historyAudioView = HistoryAudioRecordView.init(frame: self.view.bounds)
        self.view.addSubview(historyAudioView)
        historyAudioView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
    }
    

}

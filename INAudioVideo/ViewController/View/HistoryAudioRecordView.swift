//
//  HistoryAudioRecordView.swift
//  INAudioVideo
//
//  Created by kunlun on 23/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

import UIKit
import SnapKit

class HistoryAudioRecordView: UIView,UITableViewDataSource,UITableViewDelegate {

    var tableView : UITableView!
    var audioArr : [String]?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView(){
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.top.equalToSuperview()
        }
        tableView.backgroundColor = UIColor.clear
    
        audioArr = IN_FilePathManager.getAllVoicePathName()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioArr?.count ?? 0
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell =  tableView.dequeueReusableCell(withIdentifier: "HistoryAudioRecordViewCell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "HistoryAudioRecordViewCell")
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
}

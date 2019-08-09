//
//  UIColor+Custom.swift
//  INAudioVideo
//
//  Created by kunlun on 23/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(colorValue : Int ) {
        let r = CGFloat((colorValue & 0xFF0000) >> 16)
        let g = CGFloat((colorValue & 0xFF00) >> 8)
        let b = CGFloat(colorValue & 0xFF)
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: CGFloat(1.0))
    }
    
    convenience init(R:Int,G:Int,B:Int,A:Float)
    {
        let r = CGFloat(R)/255.0
        let g = CGFloat(G)/255.0
        let b = CGFloat(B)/255.0
        let a = CGFloat(A)
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}



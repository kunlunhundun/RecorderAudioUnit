//
//  INConst.h
//  INAudioVideoNote
//
//  Created by kunlun on 25/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#ifndef INConst_h
#define INConst_h

#define IN_IPHONE_WIDTH         [UIScreen mainScreen].bounds.size.width
#define IN_IPHONE_HEIGHT        [UIScreen mainScreen].bounds.size.height

#define IS_IPHONE_X_IN (IN_IPHONE_HEIGHT == 812.0f) ? YES : NO
#define IS_IPHONE_4SZ (IN_IPHONE_WIDTH == 320) ? YES : NO
#define IS_IPHONE_47SZ (IN_IPHONE_WIDTH == 375) ? YES : NO
#define IS_IPHONE_55SZ (IN_IPHONE_WIDTH == 540) ? YES : NO



#define STATUS_HEIGHT         ((IS_IPHONE_X_IN==YES)?44.0f:20.0f)
#define STATUS_NAVI_HEIGHT    ((IS_IPHONE_X_IN==YES)?88.0f:64.0f)
#define TABBAR_HEIGHT         ((IS_IPHONE_X_IN==YES)?83.0f:49.0f)
#define IPHONEX_EXTRA_HEIGHT   ((IS_IPHONE_X_IN==YES)?34.0f:0.0F)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define INColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]



#endif /* INConst_h */

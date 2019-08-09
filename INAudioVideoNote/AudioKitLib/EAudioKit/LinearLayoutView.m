//
//  LinearLayoutView.m
//  EAudioKit
//
//  Created by cybercall on 15/8/4.
//  Copyright © 2015年 rcsing. All rights reserved.
//

#import "LinearLayoutView.h"


#define SUB_DIR_LEFT     0
#define SUB_DIR_RIGHT    1
#define SUB_DIR_LEFT     0
#define SUB_DIR_RIGHT    1

@implementation LinearLayoutView

-(void)config:(CGRect)layoutRect LinearLayoutDir:(LinearLayoutDir)dir
{
    _layoutDir = dir;
    _autoGrow = NO;
    self.layoutRect = layoutRect;
}

-(void)addLayoutPadding:(int)padding
{
    [self addLayoutView:nil
            withDemsion:padding subDir:(_layoutDir == LinearLayoutHor ? LinearLayoutLeft : LinearLayoutTop)];
}

-(void)addLayoutPadding:(int)padding subDir:(LinearLayoutSubDir)subDir
{
    [self addLayoutView:nil
            withDemsion:padding subDir:subDir];
}

-(void)addLayoutView:(UIView*)view withPadding:(int)padding
{
    [self addLayoutView:view
            withDemsion:(_layoutDir == LinearLayoutHor ? view.frame.size.width : view.frame.size.height)];
    
    [self addLayoutPadding:padding];
}

-(void)addLayoutView:(UIView*)view withPadding:(int)padding subDir:(LinearLayoutSubDir)subDir
{
    int dem = (_layoutDir == LinearLayoutHor ? view.frame.size.width : view.frame.size.height);
    [self addLayoutView:view withDemsion:dem subDir:subDir];
    [self addLayoutPadding:padding subDir:subDir];
}

-(void)addLayoutView:(UIView*)view
{
    [self addLayoutView:view
            withDemsion:(_layoutDir == LinearLayoutHor ? view.frame.size.width : view.frame.size.height)];
}

-(void)addLayoutView:(UIView*)view withDemsion:(int)dem
{
    [self addLayoutView:view
         withDemsion:dem
              subDir:(_layoutDir == LinearLayoutHor ? LinearLayoutLeft : LinearLayoutTop)];
}

-(void)addLayoutView:(UIView*)view withDemsion:(int)dem subDir:(LinearLayoutSubDir)subDir
{
    
    switch (_layoutDir) {
        case LinearLayoutHor:
            [self onLayoutHor:view withDemsion:dem subDir:subDir];
            break;
        case LinearLayoutVer:
            [self onLayoutVer:view withDemsion:dem subDir:subDir];
            break;
    }
}

-(void)addLayoutViewFlex:(UIView*)view
{
    CGRect frame = _layoutRect;
    
    if (_layoutDir == LinearLayoutHor)
    {
        frame.size.width = _layoutRect.size.width;
        frame.size.height = view.frame.size.height;
    }
    else //LinearLayoutVer
    {
        frame.size.height = _layoutRect.size.height;
        frame.size.width = view.frame.size.width;
    }
    
    view.frame = frame;
    CGPoint pt = view.center;
    
    if (_layoutDir == LinearLayoutHor)
    {
        pt.y = (frame.origin.y + frame.origin.y + _layoutFitRect.size.height)/2;
    }
    else //LinearLayoutVer
    {
        pt.x = (frame.origin.x + frame.origin.x + _layoutFitRect.size.width)/2;
    }
    view.center = pt;
    [self addSubview:view];

}

-(void)onLayoutHor:(UIView*)view withDemsion:(int)dem subDir:(LinearLayoutSubDir)subDir
{
    CGRect frame;
    if ( _autoGrow ) {
        if (dem > _layoutRect.size.width) {
            int grow = (dem - _layoutRect.size.width);
            _layoutRect.size.width += grow;
            
            self.width = self.width + grow;
        }
        if (view != nil && view.frame.size.height > _layoutRect.size.height) {
            self.height += view.frame.size.height - _layoutRect.size.height;
            _layoutRect.size.height = _layoutRect.size.height;
        }
    }
    if (view != nil && _layoutFitRect.size.height < view.frame.size.height) {
        _layoutFitRect.size.height = view.frame.size.height;
    }
   
    if (subDir == LinearLayoutLeft)
    {
        frame = _layoutRect;
        _layoutRect.origin.x += dem;
        
    }else //LinearLayoutRight
    {
        frame = _layoutRect;
        frame.origin.x = frame.origin.x + frame.size.width - dem;
        
    }
    if ( view != nil) {
        frame.size = CGSizeMake(dem,view.frame.size.height);
        int offset = (dem - view.frame.size.width)/2;
        frame.origin.x += offset;
        view.frame = frame;
        [self addSubview:view];
    }

    _layoutRect.size.width -= dem;
    _layoutFitRect.size.width += dem;
}

-(void)onLayoutVer:(UIView*)view withDemsion:(int)dem subDir:(LinearLayoutSubDir)subDir
{
    CGRect frame;
    if ( _autoGrow ) {
        if (dem > _layoutRect.size.height) {
            int grow = (dem - _layoutRect.size.height);
            _layoutRect.size.height += grow;
            
            self.height = self.height + grow;
        }
        if (view.frame.size.width > self.width) {
            self.width = view.frame.size.width;
        }
    }
    if (_layoutFitRect.size.width < view.frame.size.width) {
        _layoutFitRect.size.width = view.frame.size.width;
    }
    _layoutFitRect.size.height += dem;
    
    if (subDir == LinearLayoutTop)
    {
        frame = _layoutRect;
        _layoutRect.origin.y += dem;
        
    }else //LinearLayoutBottom
    {
        frame = _layoutRect;
        frame.origin.y = frame.origin.y + frame.size.height - dem;
        
    }
    
    frame.size = CGSizeMake(view.frame.size.width, dem);
    int offset = (dem - view.frame.size.height)/2;
    frame.origin.y += offset;
    _layoutRect.size.height -= dem;
    
    view.frame = frame;
    [self addSubview:view];
}

#pragma mark -- property ---
-(int)width
{
    return self.frame.size.width;
}
-(int)height
{
    return self.frame.size.height;
}

-(void)setWidth:(int)value
{
    CGRect frame = self.frame;
    frame.size.width = value;
    self.frame = frame;
}
-(void)setHeight:(int)value
{
    CGRect frame = self.frame;
    frame.size.height = value;
    self.frame = frame;
}

-(void)setLayoutRect:(CGRect)layoutRect
{
    _layoutRect = layoutRect;
    _layoutFitRect = layoutRect;
    _layoutFitRect.size.width = 0;
    _layoutFitRect.size.height = 0;
}

@end


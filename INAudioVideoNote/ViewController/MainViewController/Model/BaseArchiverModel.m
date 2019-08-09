//
//  BaseArchiverModel.m
//  INAudioVideoNote
//
//  Created by kunlun on 30/07/2019.
//  Copyright © 2019 kunlun. All rights reserved.
//

#import "BaseArchiverModel.h"
#import <objc/runtime.h>

@interface BaseArchiverModel()<NSCoding>


@end

@implementation BaseArchiverModel


// 归档
- (void)encodeWithCoder:(NSCoder *)enCoder{
    // 取得所有成员变量名
    NSArray *properNames = [[self class] propertyOfSelf];
    
    for (NSString *propertyName in properNames) {
       
        id value =  [self valueForKey:propertyName];
        [enCoder encodeObject:value forKey:propertyName];
        //SEL getSel = NSSelectorFromString(propertyName);
        // 对每一个属性实现归档
       // [enCoder encodeObject:[self performSelector:getSel] forKey:propertyName];
    }
}

// 解档
- (id)initWithCoder:(NSCoder *)aDecoder{
    // 取得所有成员变量名
    NSArray *properNames = [[self class] propertyOfSelf];
    
    for (NSString *propertyName in properNames) {
        
        id value = [aDecoder decodeObjectForKey:propertyName];
        [self setValue:value forKey:propertyName];
        // 创建指向属性的set方法
        // 1.获取属性名的第一个字符，变为大写字母
       // NSString *firstCharater = [propertyName substringToIndex:1].uppercaseString;
        // 2.替换掉属性名的第一个字符为大写字符，并拼接出set方法的方法名
        //NSString *setPropertyName = [NSString stringWithFormat:@"set%@%@:",firstCharater,[propertyName substringFromIndex:1]];
     //   SEL setSel = NSSelectorFromString(setPropertyName);
       // [self performSelector:setSel withObject:[aDecoder decodeObjectForKey:propertyName]];
    }
    return  self;
}

// 返回self的所有对象名称
+ (NSArray *)propertyOfSelf{
    unsigned int count;
    
    // 1. 获得类中的所有成员变量
    Ivar *ivarList = class_copyIvarList(self, &count);
    
    NSMutableArray *properNames =[NSMutableArray array];
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        
        // 2.获得成员属性名
        NSString *name = [NSString stringWithUTF8String:ivar_getName(ivar)];
        
        // 3.除去下划线，从第一个角标开始截取
        NSString *key = [name substringFromIndex:1];
        
        [properNames addObject:key];
    }
    
    return [properNames copy];
}



@end

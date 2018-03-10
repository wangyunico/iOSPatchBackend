//
//  LuValueCase.h
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/28.
//  Copyright © 2017年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LuValueCase : NSObject


// 用于封装当前类型

+(LuValueCase *)incase:(id)value;


-(id)jsObject;

// 解箱
-(id)decase;

@end

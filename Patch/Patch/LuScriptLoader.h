//
//  LuScriptLoader.h
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface LuScriptLoader : NSObject


// 访问一个context
@property (nonatomic,strong,readonly) JSContext *context;


// 整个patch 只有一个实例
+(LuScriptLoader *)defaultLoader;

@end

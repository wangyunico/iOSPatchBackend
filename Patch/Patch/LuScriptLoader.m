//
//  LuScriptLoader.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuScriptLoader.h"
#import "LuFixCommandDispatcher.h"
#import "LuFixBaseExtension.h"
@interface LuScriptLoader ()

@property (nonatomic,strong,readwrite) JSContext *context;
@property (nonatomic,strong,readwrite) LuFixCommandDispatcher *commandDispatcher;
@end


@implementation LuScriptLoader


+(LuScriptLoader *)defaultLoader {
    static LuScriptLoader* loader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loader = [[LuScriptLoader alloc]init];
    });
    return loader;
}

-(id) init {
    
    if (self = [super init]) {
        self.context = [[JSContext alloc]init];
        self.commandDispatcher = [[LuFixCommandDispatcher alloc]initWithLuScriptLoader:self];
        [self initializeJSContext];
    }
    
    return self;
}



-(void)initializeJSContext {
    [self.context evaluateScript:@"window = this;"];
    // 定义了context 的declare 方法
    __weak __typeof(self) weakSelf = self;
    self.context[@"_lufix_declare"] = ^(JSValue *command) {
        __strong __typeof(self) strongSelf = weakSelf;
        [strongSelf.commandDispatcher dispatchCommand:command fromfunction:@"declare"];
    };
    // 定义了context 的eval 方法
    self.context[@"_lufix_evaluate"] = ^id(JSValue *command) {
        __strong __typeof(self) strongSelf = weakSelf;
       return  [strongSelf.commandDispatcher dispatchCommand:command fromfunction:@"evaluate"];
    };

}



@end

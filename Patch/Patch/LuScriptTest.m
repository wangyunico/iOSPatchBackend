//
//  LuScriptTest.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/14.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuScriptTest.h"

@interface LuScriptTest()
@end

@implementation LuScriptTest
@synthesize age = _age;

- (instancetype)init {
    if (self = [super init]) {
        _name= @"YAA";
        [self setValue:@"888" forKey:@"name"];
    }
    return self;
}

-(id)scriptTest:(NSUInteger)num{
    
    return @(num + 1);
}


- (void)start:(void(^)(NSString*,CGRect))block {
    block(@"哈哈哈",CGRectMake(1,2,300,400));
}

-(void)normalTest:(void(^)(NSString*))block{
     block(@"刘大铜真帅");
}

- (void)startBlock:(void(^)(NSString*,blockA))block {
    block(@"哈哈哈", ^(NSString* str){
        NSLog(@"blockA:%@",str);
    });
}

- (void)getClassName {
    NSLog(@"类名：%@",[self class]);
}

-(void)func:(int (^)(NSString*,NSInteger))sss{
    sss(@"颜小强",100);
}


+(id)klassTest:(NSInteger)num{
   
   return @(num + 300);
}



-(id)instanceTest:(NSInteger)num{
    NSLog(@"叶阳傻逼");
    return @(num + 456);
}


-(int (^)(NSString*,NSInteger))testBlock{
    
    int (^blk)(NSString* st,NSInteger tg) = ^(NSString* st,NSInteger tg){
        NSLog(@"str is %@, %ld",st,(long)tg); return  200;
    };
    return blk;
}


//setter & getter
- (NSString *)getMyAge {
    return [NSString stringWithFormat:@"%@+1",_age];
}

- (void)setMyAge:(NSString *)age {
    _age = age;
}


-(int)test:(int)a other:(int)b{
    return 200;
}


-(void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"王卫傻逼");
}
@end

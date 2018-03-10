//
//  LuValueCase.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/28.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuValueCase.h"


@interface LuValueCase ()

@property(nonatomic,strong) id inner;

@end

@implementation LuValueCase


+(LuValueCase *)incase:(id)value{
   
    LuValueCase* _case = [[LuValueCase alloc]init];
    _case.inner = value;
    return _case;
}

// 解箱
-(id)decase {
    return self.inner;
}


-(id)jsObject{
    
    if ([_inner isKindOfClass:[NSMutableArray class]]) {
        return @{@"origin":self,@"object":_inner,@"type":@"array",@"__octransfer":@(YES)};
    }else if ([_inner isKindOfClass:[NSMutableDictionary class]]){
        return @{@"origin":self,@"object":_inner,@"type":@"dictionary",@"__octransfer":@(YES)};
    }
    return @{@"origin":self,@"object":_inner,@"type":@"jsvalue",@"__octransfer":@(YES)};
    
}

-(void)jsDiff:(NSArray*)dest {
    if ([_inner isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray* tranfer_inner = (NSMutableArray *)_inner;
        [tranfer_inner removeAllObjects];
        [tranfer_inner addObjectsFromArray:dest];
    }
}


-(id)forwardingTargetForSelector:(SEL)aSelector {
    return _inner;
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    if ([self respondsToSelector:aSelector]) {
       return  [super methodSignatureForSelector:aSelector];
    }
    return  [self.inner methodSignatureForSelector:aSelector];
}

- (NSString *)description {
    return [_inner description];
}

@end

//
//  LuScriptTest.h
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/14.
//  Copyright © 2017年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void(^blockA)(NSString*);

@interface LuScriptTest : NSObject<UITableViewDelegate>


@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSMutableDictionary *dic;
@property(nonatomic,assign) BOOL boolTest;
@property (nonatomic,strong) NSMutableArray* arr;


@property (nonatomic,strong,readwrite) NSString *type;
@property (nonatomic,strong,getter=getMyAge,setter=setMyAge:)NSString *age;



-(id)scriptTest:(NSUInteger)num;


+(id)klassTest:(NSInteger)num;


-(id)instanceTest:(NSInteger)num;


- (void)start:(void(^)(NSString*,CGRect))block;

- (void)startBlock:(void(^)(NSString*,blockA))block;

- (void)getClassName;

-(void)normalTest:(void(^)(NSString*))block;

-(void)func:(int (^)(NSString*,NSInteger))sss;


-(int (^)(NSString*,NSInteger))testBlock;

@end

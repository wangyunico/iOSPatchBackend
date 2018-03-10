//
//  LuSubScriptTest.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/15.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuSubScriptTest.h"

@implementation LuSubScriptTest
-(id)scriptTest:(NSUInteger)num {
    [super scriptTest: num];
    return  @(100);
}




+(id)klassTest:(NSInteger)num{
    return  @(1000);
}



-(void)testCGRect:(CGRect)rect{
    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 20;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"id"];
    
    return cell;
}
@end

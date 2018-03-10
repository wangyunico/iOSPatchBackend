//
//  ViewController.m
//  PatchDemo
//
//  Created by mino on 2018/3/10.
//  Copyright © 2018年 mino. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *click;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self clickIt];
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)clickIt{
    @weakify(self);
    [[self.click rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
        @strongify(self);
        self.view.backgroundColor = [UIColor grayColor];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

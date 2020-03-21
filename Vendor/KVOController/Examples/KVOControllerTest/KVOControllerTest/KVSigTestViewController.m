//
//  KVSigTestViewController.m
//  KVSigTestApp
//
//  Created by CmST0us on 2018/8/26.
//  Copyright © 2018年 eric3u. All rights reserved.
//

#import "UILabel+Test.h"
#import "KVSigTestViewController.h"
#import <KVOController/KVOController.h>

@interface KVSigTestViewController ()

@end

@implementation KVSigTestViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _testLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 300, 48)];
        _testLabel.text = @"HAHA I AM TEST LABEL";
        _testLabel.font = [UIFont systemFontOfSize:14];
        
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)bindData {
    [self.testLabel addKVOObserver:self forKeyPath:FBKVOKeyPath(_testLabel.text) block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        NSLog(@"IN TEST VIEW: %@", newValue);
    }];
    
//    [self.testLabel addKVOObserver:self forKeyPath:FBKVOKeyPath(_testLabel.text) block:^(id  _Nullable oldValue, id  _Nullable newValue) {
//        NSLog(@"[2] IN TEST VIEW: %@", newValue);
//    }];
}

- (void)unBindData {
    [self.testLabel removeKVOObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 200, 300, 48)];
    [button setTitle:@"PRESS ME" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onButtonDown) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.testLabel];
    [self.view addSubview:button];
    
    [self bindData];
}

- (void)onButtonDown {
    self.testLabel.text = [[NSDate date] description];
//    self.testLabel.testString = [[NSDate date] description];
//    [self.testLabel removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.testLabel removeKVOObserver:self];
}
- (void)dealloc {
    NSLog(@"dealloc");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

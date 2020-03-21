//
//  KVSigTestMenuViewController.m
//  KVSigTestApp
//
//  Created by CmST0us on 2018/8/26.
//  Copyright © 2018年 eric3u. All rights reserved.
//

#import "KVSigTestMenuViewController.h"
#import "KVSigTestViewController.h"

@interface KVSigTestMenuViewController ()
@end

@implementation KVSigTestMenuViewController

- (IBAction)jumpToTestVC:(id)sender {
    UIViewController *vc = [[KVSigTestViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

//
//  ViewController.m
//  KVSigTestApp
//
//  Created by CmST0us on 2018/8/24.
//  Copyright © 2018年 eric3u. All rights reserved.
//

#import "ViewController.h"
#import <KVOController/KVOController.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segment;
@property (weak, nonatomic) IBOutlet UIView *colorView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self bindData];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)bindData {
    __weak typeof(self) target = self;
    [self addKVOObserver:self forKeyPath:FBKVOKeyPath(self.segment.selectedSegmentIndex) block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        NSNumber *number = (NSNumber *)newValue;
        UIColor *color = nil;
        switch ([number integerValue]) {
            case 0:
                color = [UIColor redColor];
                break;
            case 1:
                color = [UIColor yellowColor];
                break;
            case 2:
                color = [UIColor blueColor];
                break;
            case 3:
                color = [UIColor orangeColor];
                break;
            default:
                color = [UIColor blackColor];
                break;
        }
        target.colorView.backgroundColor = color;
    }];
    
    [self addKVOObserver:self forKeyPath:FBKVOKeyPath(self.segment.selectedSegmentIndex) block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        NSNumber *newSelect = (NSNumber *)newValue;
        NSLog(@"newSelect is %@", newSelect);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

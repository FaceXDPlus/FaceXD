//
//  XDLive2DCaptureViewController.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//
#import <ARKit/ARKit.h>
#import "XDLive2DCaptureViewController.h"
#import "XDLive2DCaptureViewModel.h"
#import "XDLive2DCaptureARKitViewModel.h"
#import "XDLive2DCaptureDlibViewModel.h"

@interface XDLive2DCaptureViewController ()
@property (nonatomic, strong) XDLive2DCaptureViewModel *viewModel;
@end

@implementation XDLive2DCaptureViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _viewModel = [[[self viewModelClass] alloc] init];
    }
    return self;
}

- (void)bindData {
    
}

#pragma mark - Data Source
- (Class)viewModelClass {
    if ([ARFaceTrackingConfiguration isSupported]) {
        return [XDLive2DCaptureARKitViewModel class];
    }
    return [XDLive2DCaptureDlibViewModel class];
}

@end

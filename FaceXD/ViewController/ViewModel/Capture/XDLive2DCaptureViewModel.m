//
//  XDLive2DCaptureViewModel.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDLive2DCaptureViewModel.h"

@interface XDLive2DCaptureViewModel ()
@property (nonatomic, assign) BOOL isCapturing;
@end

@implementation XDLive2DCaptureViewModel

- (void)startCapture {
    self.isCapturing = YES;
}

- (void)stopCapture {
    self.isCapturing = NO;
}

@end

//
//  XDLive2DCaptureViewModel.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDLive2DCaptureViewModel.h"
#import "XDUserDefineKeys.h"
@interface XDLive2DCaptureViewModel ()
@property (nonatomic, assign) BOOL isCapturing;
@end

@implementation XDLive2DCaptureViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        _advanceMode = [userDefault boolForKey:XDUserDefineKeySubmitAdvancedSwitch];
    }
    return self;
}

- (void)startCapture {
    self.isCapturing = YES;
}

- (void)stopCapture {
    self.isCapturing = NO;
}

- (void)setAdvanceMode:(BOOL)advanceMode {
    _advanceMode = advanceMode;
    [[NSUserDefaults standardUserDefaults] setBool:_advanceMode forKey:XDUserDefineKeySubmitAdvancedSwitch];
}

- (NSArray<NSString *> *)filterSendKeys {
    static NSArray *array = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        array = @[
            LAppParamBodyAngleX,
            LAppParamBodyAngleY,
            LAppParamBodyAngleZ,
        ];
    });
    return array;
}

@end

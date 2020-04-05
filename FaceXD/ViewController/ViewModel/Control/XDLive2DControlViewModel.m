//
//  XDLive2DControlViewModel.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <KVOController/KVOController.h>
#import "XDLive2DControlViewModel.h"
#import "XDRawJSONSocketService.h"
#import "XDPackManager.h"
#import "XDUserDefineKeys.h"

#import "XDLive2DCaptureViewModel.h"

@interface XDLive2DControlViewModel ()
@property (nonatomic, strong) XDRawJSONSocketService *jsonSocketService;
@property (nonatomic, assign) BOOL isCapturing;
@property (nonatomic, assign) BOOL isSubmiting;

@property (nonatomic, strong) XDLive2DCaptureViewModel *captureViewModel;
@end

@implementation XDLive2DControlViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _jsonSocketService = [[XDRawJSONSocketService alloc] init];
        [[XDPackManager sharedInstance] registerService:_jsonSocketService];
        
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        _appVersion = [NSString stringWithFormat:@"%@ b%@", version, build];
        NSLog(NSLocalizedString(@"startupLog", nil) , version, build);
        
        NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
        NSString *address = [accountDefaults objectForKey:XDUserDefineKeySubmitAddress];
        NSString *port = [accountDefaults objectForKey:XDUserDefineKeySubmitSocketPort];
        if(address == nil){
            address = @"127.0.0.1:12345";
            [accountDefaults setObject:address forKey:XDUserDefineKeySubmitAddress];
            [accountDefaults synchronize];
        }
        if(port == nil){
            port = @"8040";
            [accountDefaults setObject:port forKey:XDUserDefineKeySubmitSocketPort];
            [accountDefaults synchronize];
        }
        _host = address;
        _port = port;
        
        _showJSON = [accountDefaults boolForKey:XDUserDefineKeySubmitJSONSwitch];
        _advanceMode = [accountDefaults boolForKey:XDUserDefineKeySubmitAdvancedSwitch];
        
        NSNumber *alignmentNumber = [accountDefaults objectForKey:XDUserDefineKeySubmitCameraAlignment];
        if (alignmentNumber == nil) {
            alignmentNumber = @(YES);
            [accountDefaults setObject:alignmentNumber forKey:XDUserDefineKeySubmitCameraAlignment];
        }
        _relativeMode = alignmentNumber.boolValue;
        _isSubmiting = NO;
        [self bindData];
    }
    return self;
}

- (void)bindData {
    __weak typeof(self) weakSelf = self;
    [self.jsonSocketService addKVOObserver:self
                                forKeyPath:FBKVOKeyPath(_jsonSocketService.isPaused)
                                     block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        weakSelf.isSubmiting = !weakSelf.jsonSocketService.isPaused;
    }];
    self.isSubmiting = !self.jsonSocketService.isPaused;
}

#pragma mark - Public Method

- (NSError *)connect {
    NSError *err = nil;
    [self.jsonSocketService setupServiceWithEndpointHost:self.host
                                                    port:self.port
                                                 timeout:5 error:&err];
    return err;
}

- (void)disconnect {
    [self.jsonSocketService disconnect];
}

#pragma mark - Capture
- (void)startCapture {
    [self.captureViewModel startCapture];
}

- (void)stopCapture {
    [self.captureViewModel stopCapture];
}
- (void)attachLive2DCaptureViewModel:(XDLive2DCaptureViewModel *)captureViewModel {
    [self.captureViewModel removeKVOObserver:self];
    self.captureViewModel = captureViewModel;
    __weak typeof(self) weakSelf = self;
    [self.captureViewModel addKVOObserver:self forKeyPath:FBKVOKeyPath(_captureViewModel.isCapturing)
                                    block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        weakSelf.isCapturing = weakSelf.captureViewModel.isCapturing;
    }];
    self.isCapturing = self.captureViewModel.isCapturing;
}
#pragma mark - Submit
- (void)startSubmit {
    [self.jsonSocketService resume];
    self.isSubmiting = YES;
}

- (void)stopSubmit {
    [self.jsonSocketService pause];
    self.isSubmiting = NO;
}

@end

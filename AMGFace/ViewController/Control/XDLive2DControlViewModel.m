//
//  XDLive2DControlViewModel.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <KVOController/KVOController.h>
#import "XDLive2DControlViewModel.h"
#import "XDPackManager.h"
#import "XDUserDefineKeys.h"

#import "XDLive2DCaptureViewModel.h"

#define kXDWebSocketServerListenPort (22546)

@interface XDLive2DControlViewModel ()
@property (nonatomic, strong) XDWebSocketService *webSocketService;
@property (nonatomic, strong) XDWebSocketServerService *webSocketServerService;
@property (nonatomic, assign) BOOL isSubmiting;

@property (nonatomic, strong) XDLive2DCaptureViewModel *captureViewModel;
@end

@implementation XDLive2DControlViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _webSocketService = [[XDWebSocketService alloc] init];
        _webSocketServerService = [[XDWebSocketServerService alloc] init];
        [[XDPackManager sharedInstance] registerService:_webSocketService];
        [[XDPackManager sharedInstance] registerService:_webSocketServerService];
        
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        _appVersion = [NSString stringWithFormat:@"%@ b%@", version, build];
        NSLog(NSLocalizedString(@"startupLog", nil) , version, build);
        
        NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
        NSString *address = [accountDefaults objectForKey:XDUserDefineKeySubmitAddress];
        NSString *port = [accountDefaults objectForKey:XDUserDefineKeySubmitSocketPort];
        if(address == nil){
            address = @"192.168.1.100";
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
        
        [self bindData];
    }
    return self;
}

- (void)bindData {
    
}

- (void)setHost:(NSString *)host {
    _host = host;
    [[NSUserDefaults standardUserDefaults] setObject:host forKey:XDUserDefineKeySubmitAddress];
}

- (void)setPort:(NSString *)port {
    _port = port;
    [[NSUserDefaults standardUserDefaults] setObject:port forKey:XDUserDefineKeySubmitSocketPort];
}

#pragma mark - Public Method

- (NSError *)connect {
    NSError *err = nil;
    NSString *url = [NSString stringWithFormat:@"ws://%@:%@", self.host, self.port];
    [self.webSocketService setupServiceWithURL:[NSURL URLWithString:url] timeout:5 error:&err];
    return err;
}

- (void)disconnect {
    [self.webSocketService disconnect];
}

- (NSError *)startLocalServer {
    NSError *err = nil;
    [self.webSocketServerService setupServiceWithLocalPort:kXDWebSocketServerListenPort
                                                     error:&err];
    return err;
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
}

@end

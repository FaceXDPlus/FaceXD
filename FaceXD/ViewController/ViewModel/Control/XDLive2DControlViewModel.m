//
//  XDLive2DControlViewModel.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDLive2DControlViewModel.h"
#import "XDRawJSONSocketService.h"
#import "XDPackManager.h"

@interface XDLive2DControlViewModel ()
@property (nonatomic, strong) XDRawJSONSocketService *jsonSocketService;
@end

@implementation XDLive2DControlViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _jsonSocketService = [[XDRawJSONSocketService alloc] init];
        [[XDPackManager sharedInstance] registerService:_jsonSocketService];
    }
    return self;
}

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

@end

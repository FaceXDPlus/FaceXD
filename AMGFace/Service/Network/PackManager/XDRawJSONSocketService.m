//
//  XDRawJSONSocketService.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <GCDAsyncSocket.h>
#import "XDRawJSONSocketService.h"
#import "XDRawJSONNetworkPack.h"

#define kXDRawJSONSocketServiceSocketTag (10086)

@interface XDRawJSONSocketService () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, strong) NSError *lastError;
@end

@implementation XDRawJSONSocketService

- (instancetype)init {
    self = [super init];
    if (self) {
        _socketQueue = dispatch_queue_create("XDRawJSONSocketService::SocketQueue", DISPATCH_QUEUE_SERIAL);
        _isConnected = NO; 
    }
    return self;
}

- (void)setupServiceWithEndpointHost:(NSString *)endpointHost
                                port:(NSString *)endpointPort
                             timeout:(NSTimeInterval)timeout
                               error:(NSError **)error {
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketQueue];
    [self.socket connectToHost:endpointHost
                        onPort:[endpointPort intValue]
                   withTimeout:timeout
                         error:error];
}

- (void)disconnect {
    [self.socket disconnect];
}
#pragma mark - Subclass Override
- (BOOL)canHandlePack:(XDBaseNetworkPack *)pack {
    if ([pack isKindOfClass:[XDRawJSONNetworkPack class]]) {
        return YES;
    }
    return NO;
}

- (void)handlePack:(XDBaseNetworkPack *)pack {
    if (!self.isConnected) {
        return;
    }
    NSData *data = [pack serialize];
    [self.socket writeData:data withTimeout:-1 tag:kXDRawJSONSocketServiceSocketTag];
}

#pragma mark - Delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.isConnected = YES;
    self.lastError = nil;
    [self.socket readDataWithTimeout:-1 tag:kXDRawJSONSocketServiceSocketTag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.isConnected = NO;
    self.lastError = err;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.socket readDataWithTimeout:-1 tag:kXDRawJSONSocketServiceSocketTag];
}

@end

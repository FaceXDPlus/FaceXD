//
//  XDWebSocketServerService.m
//  AMGFace
//
//  Created by CmST0us on 2020/6/6.
//  Copyright © 2020 AMG. All rights reserved.
//

#import <PocketSocket/PSWebSocketServer.h>
#import "XDWebSocketServerService.h"
#import "XDRawJSONNetworkPack.h"

@interface XDWebSocketServerService () <PSWebSocketServerDelegate>
@property (nonatomic, strong) PSWebSocketServer *server;
@property (nonatomic, strong) NSMutableArray<PSWebSocket *> *clients;
@property (nonatomic, strong) dispatch_queue_t serverDelegateQueue;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) NSError *lastError;
@end

@implementation XDWebSocketServerService

- (instancetype)init {
    self = [super init];
    if (self) {
        _clients = [[NSMutableArray alloc] init];
        _serverDelegateQueue = dispatch_queue_create("WebSocketServerDelegateQueue", DISPATCH_QUEUE_SERIAL);
        _isRunning = NO;
    }
    return self;
}

- (void)setupServiceWithLocalPort:(NSInteger)port
                            error:(NSError *__autoreleasing  _Nullable *)error {
    self.server = [PSWebSocketServer serverWithHost:@"0.0.0.0" port:port];
    self.server.delegate = self;
    self.server.delegateQueue = self.serverDelegateQueue;
    [self.server start];
    self.isRunning = YES;
}

- (void)close {
    [self.server stop];
}

- (BOOL)canHandlePack:(XDBaseNetworkPack *)pack {
    if ([pack isKindOfClass:[XDRawJSONNetworkPack class]]) {
        return YES;
    }
    return NO;
}

- (void)handlePack:(XDBaseNetworkPack *)pack {
    if (!self.isRunning) {
        return;
    }
    if (self.clients.count == 0) {
        return;
    }
    NSData *data = [pack serialize];
    [self.clients enumerateObjectsUsingBlock:^(PSWebSocket * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj send:data];
    }];
}

#pragma mark - Delegate
- (void)server:(PSWebSocketServer *)server didFailWithError:(NSError *)error {
    self.lastError = error;
    self.isRunning = NO;
}

- (void)serverDidStart:(PSWebSocketServer *)server {
    self.isRunning = YES;
    self.lastError = nil;
}

- (void)serverDidStop:(PSWebSocketServer *)server {
    self.isRunning = NO;
    self.lastError = nil;
}

- (void)server:(PSWebSocketServer *)server webSocketDidOpen:(PSWebSocket *)webSocket {
    @synchronized (self) {
        [self.clients addObject:webSocket];
    }
}

- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    /// pass
}

- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    @synchronized (self) {
        [self.clients removeObject:webSocket];
    }
}

- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    @synchronized (self) {
        [self.clients removeObject:webSocket];
    }
}

@end

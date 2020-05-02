//
//  XDWebSocketService.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/25.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <SocketRocket/SRWebSocket.h>
#import "XDWebSocketService.h"
#import "XDRawJSONNetworkPack.h"

@interface XDWebSocketService () <SRWebSocketDelegate>
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, strong) NSError *lastError;
@end

@implementation XDWebSocketService

- (instancetype)init {
    self = [super init];
    if (self) {
        _isConnected = NO;
        _delegateQueue = dispatch_queue_create("XDWebSocketService::DelegateQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setupServiceWithURL:(NSURL *)url
                    timeout:(NSTimeInterval)timeout
                      error:(NSError *__autoreleasing  _Nullable *)error {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeout];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    self.webSocket.delegate = self;
    [self.webSocket setDelegateDispatchQueue:self.delegateQueue];
    [self.webSocket open];
}

- (void)disconnect {
    [self.webSocket close];
}

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
    [self.webSocket send:data];
}

#pragma mark - Delegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSString *s = nil;
    if ([message isKindOfClass:[NSData class]]) {
        s = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    } else if ([message isKindOfClass:[NSString class]]) {
        s = [message copy];
    }
    
    XDRawJSONNetworkPack *pack = [[XDRawJSONNetworkPack alloc] initWithData:[s dataUsingEncoding:NSUTF8StringEncoding]];
    [pack deserialize];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(service:didReceivePack:error:)]) {
        [self.delegate service:self didReceivePack:pack error:nil];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    self.isConnected = YES;
    self.lastError = nil;
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    self.isConnected = NO;
    self.lastError = error;
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    self.isConnected = NO;
    self.lastError = nil;
}

@end

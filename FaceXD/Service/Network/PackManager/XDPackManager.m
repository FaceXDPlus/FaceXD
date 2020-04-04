//
//  XDPackManager.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDPackManager.h"

@interface XDPackManagerListenContext : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) XDPackManagerCompletion handler;
@property (nonatomic, assign) Class listenClassType;
@property (nonatomic, assign) XDPackManagerListenType listenType;
@end
@implementation XDPackManagerListenContext
@end

@interface XDPackManager () <XDBaseServiceDelegate>
@property (nonatomic, strong) NSMutableArray<XDBaseService *> *services;
@property (nonatomic, strong) NSLock *servicesRegisterLock;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<XDPackManagerListenContext *> *> *listenMap;
@property (nonatomic, strong) NSRecursiveLock *listenMapLock;

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) dispatch_queue_t sendQueue;

@end

@implementation XDPackManager

+ (instancetype)sharedInstance {
    @synchronized (self) {
        static dispatch_once_t onceToken;
        static XDPackManager *instance = nil;
        dispatch_once(&onceToken, ^{
            instance = [[XDPackManager alloc] init];
        });
        return instance;
    }
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _services = [[NSMutableArray alloc] init];
        _servicesRegisterLock = [[NSLock alloc] init];
        _listenMap = [[NSMutableDictionary alloc] init];
        _listenMapLock = [[NSRecursiveLock alloc] init];
        _dispatchQueue = dispatch_queue_create("XDPackManager::DispatchQueue", DISPATCH_QUEUE_SERIAL);
        _sendQueue = dispatch_queue_create("XDPackManager::SendQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)registerService:(XDBaseService *)service {
    if (service == nil ||
        ![service isKindOfClass:[XDBaseService class]]) {
        return;
    }
    [self.servicesRegisterLock lock];
    if (![self.services containsObject:service]) {
        [self.services addObject:service];
        service.delegate = self;
    }
    [self.servicesRegisterLock unlock];
}

- (void)removeService:(XDBaseService *)service {
    if (service == nil ||
        ![service isKindOfClass:[XDBaseService class]]) {
        return;
    }
    [self.servicesRegisterLock lock];
    if ([self.services containsObject:service]) {
        [self.services removeObject:service];
    }
    [self.servicesRegisterLock unlock];
}

#pragma mark - Pack Method
- (void)sendPack:(XDBaseNetworkPack *)pack
        observer:(NSObject *)observer
      completion:(XDPackManagerCompletion)completion {
    [self.servicesRegisterLock lock];
    [self.services enumerateObjectsUsingBlock:^(XDBaseService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj canHandlePack:pack]) {
            dispatch_async(self.sendQueue, ^{
                [obj handlePack:pack];
            });
        }
    }];
    [self.servicesRegisterLock unlock];
    
    [self listenPack:[pack class]
                type:XDPackManagerListenTypeOnce
            observer:observer
             handler:completion];
}

- (void)listenPack:(Class)pack
          observer:(NSObject *)observer
           handler:(XDPackManagerCompletion)handler {
    [self listenPack:pack
                type:XDPackManagerListenTypeKeep
            observer:observer
             handler:handler];
}

- (void)listenPack:(Class)pack
              type:(XDPackManagerListenType)listenType
          observer:(NSObject *)observer
           handler:(XDPackManagerCompletion)handler {
    [self.listenMapLock lock];
    
    XDPackManagerListenContext *context = [[XDPackManagerListenContext alloc] init];
    context.listenClassType = pack;
    context.observer = observer;
    context.handler = handler;
    context.listenType = listenType;
    
    NSMutableArray *listeners = [self.listenMap objectForKey:NSStringFromClass(pack)];
    if (listeners == nil) {
        listeners = [[NSMutableArray alloc] init];
        [self.listenMap setObject:listeners forKey:NSStringFromClass(pack)];
    }
    [listeners addObject:context];
    
    [self.listenMapLock unlock];
}

- (void)removeAllListenPackWithObserver:(NSObject *)observer {
    [self.listenMapLock lock];
    [[self.listenMap allKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Class cls = NSClassFromString(obj);
        if (cls) {
            [self removeListenPack:cls observer:observer];
        }
    }];
    [self.listenMapLock unlock];
}

- (void)removeListenPack:(Class)packClass observer:(NSObject *)observer; {
    [self.listenMapLock lock];
    
    NSMutableArray<XDPackManagerListenContext *> *listeners = [self.listenMap objectForKey:NSStringFromClass(packClass)];
    NSMutableArray *removeObj = [[NSMutableArray alloc] init];
    if (listeners) {
        [listeners enumerateObjectsUsingBlock:^(XDPackManagerListenContext * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.handler == nil ||
                obj.observer == nil ||
                obj.observer == observer ||
                obj.listenClassType == NULL ||
                obj.listenClassType == packClass) {
                [removeObj addObject:obj];
            }
        }];
        [listeners removeObjectsInArray:removeObj];
    }

    [self.listenMapLock unlock];
}

- (void)dispatchPack:(XDBaseNetworkPack *)pack error:(NSError *)error {
    [self.listenMapLock lock];
    
    NSMutableArray<XDPackManagerListenContext *> *listeners = [self.listenMap objectForKey:NSStringFromClass([pack class])];
    NSMutableArray *removeObj = [[NSMutableArray alloc] init];
    if (listeners) {
        [listeners enumerateObjectsUsingBlock:^(XDPackManagerListenContext * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.handler == nil ||
                obj.observer == nil ||
                obj.listenType == XDPackManagerListenTypeOnce) {
                [removeObj addObject:obj];
            }
            if (obj.handler &&
                obj.observer) {
                dispatch_async(self.dispatchQueue, ^{
                    obj.handler(pack, error);
                });   
            }
        }];
        [listeners removeObjectsInArray:removeObj];
    }
    
    [self.listenMapLock unlock];
}

#pragma mark - Delegate
- (void)service:(XDBaseService *)service didReceivePack:(XDBaseNetworkPack *)pack error:(NSError *)error {
    [self dispatchPack:pack error:error];
}

@end

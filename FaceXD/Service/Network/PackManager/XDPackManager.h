//
//  XDPackManager.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDBaseService.h"
#import "XDBaseNetworkPack.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^XDPackManagerCompletion)(XDBaseNetworkPack *response, NSError * _Nullable error);

typedef NS_ENUM(NSUInteger, XDPackManagerListenType) {
    XDPackManagerListenTypeKeep,
    XDPackManagerListenTypeOnce,
};

@interface XDPackManager : NSObject

@property (nonatomic, readonly) NSArray<XDBaseService *> *currentService;

+ (instancetype)sharedInstance;

- (void)registerService:(XDBaseService *)service;
- (void)removeService:(XDBaseService *)service;

- (void)sendPack:(XDBaseNetworkPack *)pack
        observer:(NSObject *)observer
      completion:(XDPackManagerCompletion _Nullable)completion;

- (void)listenPack:(Class)pack
          observer:(NSObject *)observer
           handler:(XDPackManagerCompletion)handler;

- (void)listenPack:(Class)pack
              type:(XDPackManagerListenType)listenType
          observer:(NSObject *)observer
           handler:(XDPackManagerCompletion)handler;

@end

NS_ASSUME_NONNULL_END

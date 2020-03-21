/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSObject+FBKVOController.h"

#import <objc/message.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Convert your project to ARC or specify the -fobjc-arc flag.
#endif

#pragma mark NSObject Category -

NS_ASSUME_NONNULL_BEGIN

static void *NSObjectKVOControllerKey = &NSObjectKVOControllerKey;

@implementation NSObject (FBKVOController)

- (FBKVOController *)KVOController
{
  id controller = objc_getAssociatedObject(self, NSObjectKVOControllerKey);
  // lazily create the KVOController
  if (nil == controller) {
    controller = [FBKVOController controllerWithObserver:self];
    objc_setAssociatedObject(self, NSObjectKVOControllerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return controller;
}

- (void)addKVOObserver:(NSObject *)observer
            forKeyPath:(NSString *)aKeyPath
                 block:(FBKVOControllerChangeBlock)block {
  FBKVOController *controller = [self KVOController];
  [controller observer:observer keyPath:aKeyPath block:block];
}

- (void)addKVOObserver:(NSObject *)observer
            forKeyPath:(NSString *)aKeyPath
                action:(SEL)aSelector {
  FBKVOController *controller = [self KVOController];
  [controller observer:observer keyPath:aKeyPath action:aSelector];
}

- (void)addKVOObserver:(NSObject *)observer
           forKeyPaths:(NSArray<NSString *> *)keyPaths
                 block:(FBKVOControllerChangeBlock)block {
  FBKVOController *controller = [self KVOController];
  [controller observer:observer keyPaths:keyPaths block:block];
}

- (void)addKVOObserver:(NSObject *)observer
           forKeyPaths:(NSArray<NSString *> *)keyPaths
                action:(SEL)aSelector {
  FBKVOController *controller = [self KVOController];
  [controller observer:observer keyPaths:keyPaths action:aSelector];
}

- (void)removeKVOObserver:(NSObject *)observer {
  FBKVOController *controller = [self KVOController];
  [controller unobserve:self];
}

- (void)removeKVOObserver:(NSObject *)observer forKeyPath:(NSString *)aKeyPath {
  FBKVOController *controller = [self KVOController];
  [controller unobserve:observer keyPath:aKeyPath];
}

- (void)removeAllKVOObserver {
  FBKVOController *controller = [self KVOController];
  [controller removeAllKVOObserver];
}

@end


NS_ASSUME_NONNULL_END

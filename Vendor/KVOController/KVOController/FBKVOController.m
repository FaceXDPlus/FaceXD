/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBKVOController.h"

#import <objc/message.h>
#import <pthread.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Convert your project to ARC or specify the -fobjc-arc flag.
#endif

#pragma mark Utilities -

static NSString *describe_option(NSKeyValueObservingOptions option)
{
  switch (option) {
    case NSKeyValueObservingOptionNew:
      return @"NSKeyValueObservingOptionNew";
      break;
    case NSKeyValueObservingOptionOld:
      return @"NSKeyValueObservingOptionOld";
      break;
    case NSKeyValueObservingOptionInitial:
      return @"NSKeyValueObservingOptionInitial";
      break;
    case NSKeyValueObservingOptionPrior:
      return @"NSKeyValueObservingOptionPrior";
      break;
    default:
      NSCAssert(NO, @"unexpected option %tu", option);
      break;
  }
  return nil;
}

static void append_option_description(NSMutableString *s, NSUInteger option)
{
  if (0 == s.length) {
    [s appendString:describe_option(option)];
  } else {
    [s appendString:@"|"];
    [s appendString:describe_option(option)];
  }
}

static NSUInteger enumerate_flags(NSUInteger *ptrFlags)
{
  NSCAssert(ptrFlags, @"expected ptrFlags");
  if (!ptrFlags) {
    return 0;
  }

  NSUInteger flags = *ptrFlags;
  if (!flags) {
    return 0;
  }

  NSUInteger flag = 1 << __builtin_ctzl(flags);
  flags &= ~flag;
  *ptrFlags = flags;
  return flag;
}

static NSString *describe_options(NSKeyValueObservingOptions options)
{
  NSMutableString *s = [NSMutableString string];
  NSUInteger option;
  while (0 != (option = enumerate_flags(&options))) {
    append_option_description(s, option);
  }
  return s;
}

#pragma mark _FBKVOInfo -

/**
 @abstract The key-value observation info.
 @discussion Object equality is only used within the scope of a controller instance. Safely omit controller from equality definition.
 */
@interface _FBKVOInfo : NSObject
@end

@implementation _FBKVOInfo
{
@public
  __weak FBKVOController *_controller;
  __weak id _observer;
  NSString *_keyPath;
  NSKeyValueObservingOptions _options;
  SEL _action;
  void *_context;
  FBKVOControllerChangeBlock _block;
}

- (instancetype)initWithController:(FBKVOController *)controller
                          observer:(nullable id)observer
                           keyPath:(NSString *)keyPath
                           options:(NSKeyValueObservingOptions)options
                             block:(nullable FBKVOControllerChangeBlock)block
                            action:(nullable SEL)action
                           context:(nullable void *)context
{
  self = [super init];
  if (nil != self) {
    _controller = controller;
    _block = [block copy];
    _keyPath = [keyPath copy];
    _options = options;
    _action = action;
    _context = context;
    _observer = observer;
  }
  return self;
}


- (NSString *)debugDescription
{
  NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p keyPath:%@", NSStringFromClass([self class]), self, _keyPath];
  if (0 != _options) {
    [s appendFormat:@" options:%@", describe_options(_options)];
  }
  if (NULL != _action) {
    [s appendFormat:@" action:%@", NSStringFromSelector(_action)];
  }
  if (NULL != _context) {
    [s appendFormat:@" context:%p", _context];
  }
  if (NULL != _block) {
    [s appendFormat:@" block:%p", _block];
  }
  if (NULL != _observer) {
    [s appendFormat:@" observer:%p", _observer];
  }
  [s appendString:@">"];
  return s;
}


@end

#pragma mark FBKVOController -

@implementation FBKVOController
{
  /// keyPath作为Key, 监听参数数组作为Value，用于改进FBController不能在多处监听的问题;
  NSMutableDictionary<NSString *, NSMutableArray<_FBKVOInfo *> *> *_objectInfosMap;
  NSMutableArray <NSString *> *_observedKeyPath;
  pthread_mutex_t _lock;
}

#pragma mark Lifecycle -

+ (instancetype)controllerWithObserver:(nullable id)observer
{
  return [[self alloc] initWithObserver:observer];
}

- (instancetype)initWithObserver:(nullable id)observer
{
  self = [super init];
  if (nil != self) {
    _sender = observer;
    _observedKeyPath = [[NSMutableArray alloc] init];
    _objectInfosMap = [[NSMutableDictionary alloc] init];
    pthread_mutex_init(&_lock, NULL);
  }
  return self;
}

- (void)dealloc
{
  [self unobserveAll];
  pthread_mutex_destroy(&_lock);
}

#pragma mark Properties -


- (NSString *)debugDescription
{
  NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p", NSStringFromClass([self class]), self];
  [s appendFormat:@" sender:<%@:%p>", NSStringFromClass([_sender class]), _sender];

  // lock
  pthread_mutex_lock(&_lock);

  if (0 != _objectInfosMap.count) {
    [s appendString:@"\n  "];
  }

  for (id object in _objectInfosMap) {
    NSMutableArray<_FBKVOInfo *> *infos = [_objectInfosMap objectForKey:object];
    NSMutableArray *infoDescriptions = [NSMutableArray arrayWithCapacity:infos.count];
    [infos enumerateObjectsUsingBlock:^(_FBKVOInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      [infoDescriptions addObject:obj.debugDescription];
    }];
    [s appendFormat:@"%@ -> %@", object, infoDescriptions];
  }

  // unlock
  pthread_mutex_unlock(&_lock);

  [s appendString:@">"];
  return s;
}


#pragma mark Utilities -

- (void)_observeInfo:(_FBKVOInfo *)info
{
  if (info->_observer == nil) return;
  
  // lock
  pthread_mutex_lock(&_lock);

  /// 先拿keyPath
  NSString *keyPath = [info->_keyPath copy];
  // 判断当前keyPath是否已经监听
  if (![_observedKeyPath containsObject:keyPath]) {
    // 当前keyPath如果没有监听的话加到系统KVO监听列表里面
    [_sender addObserver:self forKeyPath:keyPath options:info->_options context:info->_context];
    [_observedKeyPath addObject:keyPath];
  }
  
  // 取回当前监听信息列表
  NSMutableArray *observerMap = [_objectInfosMap valueForKey:keyPath];
  if (observerMap == nil) {
    observerMap = [[NSMutableArray alloc] init];
    [_objectInfosMap setObject:observerMap forKey:keyPath];
  }
  
  // 将当前监听信息加入到监听列表中
  [observerMap addObject:info];
  pthread_mutex_unlock(&_lock);
}

- (void)_unobserveWithKeyPath:(NSString *)keyPath
                     observer:(id)object {
  // lock
  pthread_mutex_lock(&_lock);
  
  /// 判断keyPath是否在监听列表里
  if ([_observedKeyPath containsObject:keyPath]) {
    /// 在监听列表则移除
    [_observedKeyPath removeObject:keyPath];
    [_sender removeObserver:self forKeyPath:keyPath];
  }
  
  /// 遍历搜索keyPath的所有监听者, 如果是object则移除
  NSMutableArray<_FBKVOInfo *> *infos = [_objectInfosMap valueForKey:keyPath];
  NSMutableArray *deletedInfo = [NSMutableArray array];
  [infos enumerateObjectsUsingBlock:^(_FBKVOInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if (obj->_observer == object) {
      [deletedInfo addObject:obj];
    }
  }];
  [infos removeObjectsInArray:deletedInfo];

  // unlock
  pthread_mutex_unlock(&_lock);
}

- (void)_unobserve:(id)object
{
  // lock
  pthread_mutex_lock(&_lock);

  /// 遍历监听信息，拿到监听者的info
  [_objectInfosMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<_FBKVOInfo *> * _Nonnull obj, BOOL * _Nonnull stop) {
    NSMutableArray *deletedObject = [NSMutableArray array];
    [obj enumerateObjectsUsingBlock:^(_FBKVOInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      if (obj->_observer == object) {
        [deletedObject addObject:obj];
      }
    }];
    [obj removeObjectsInArray:deletedObject];
  }];

  // unlock
  pthread_mutex_unlock(&_lock);
}

- (void)_unobserveAll
{
  // lock
  pthread_mutex_lock(&_lock);

  [_observedKeyPath enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [_sender removeObserver:self forKeyPath:obj];
  }];
  
  [_objectInfosMap removeAllObjects];
  [_observedKeyPath removeAllObjects];
  
  // unlock
  pthread_mutex_unlock(&_lock);
}

#pragma mark API -

- (void)observer:(nullable id)object keyPath:(NSString *)keyPath block:(FBKVOControllerChangeBlock)block
{
  NSAssert(0 != keyPath.length && NULL != block, @"missing required parameters observer:%@ keyPath:%@ block:%p", object, keyPath, block);
  if (nil == object || 0 == keyPath.length || NULL == block) {
    return;
  }

  // create info
  _FBKVOInfo *info = [[_FBKVOInfo alloc] initWithController:self observer:object keyPath:keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:block action:nil context:nil];
  // observe object with info
  [self _observeInfo:info];
}


- (void)observer:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths block:(FBKVOControllerChangeBlock)block
{
  NSAssert(0 != keyPaths.count && NULL != block, @"missing required parameters observer:%@ keyPath:%@ block:%p", object, keyPaths, block);
  if (nil == object || 0 == keyPaths.count || NULL == block) {
    return;
  }

  for (NSString *keyPath in keyPaths) {
    [self observer:object keyPath:keyPath block:block];
  }
}

- (void)observer:(nullable id)object keyPath:(NSString *)keyPath action:(SEL)action
{
  NSAssert(0 != keyPath.length && NULL != action, @"missing required parameters observe:%@ keyPath:%@ action:%@", object, keyPath, NSStringFromSelector(action));
  NSAssert([object respondsToSelector:action], @"%@ does not respond to %@", object, NSStringFromSelector(action));
  if (nil == object || 0 == keyPath.length || NULL == action) {
    return;
  }

  // create info
  _FBKVOInfo *info = [[_FBKVOInfo alloc] initWithController:self observer:object keyPath:keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:nil action:action context:nil];

  // observe object with info
  [self _observeInfo:info];
}

- (void)observer:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths action:(SEL)action
{
  NSAssert(0 != keyPaths.count && NULL != action, @"missing required parameters observe:%@ keyPath:%@ action:%@", object, keyPaths, NSStringFromSelector(action));
  NSAssert([object respondsToSelector:action], @"%@ does not respond to %@", object, NSStringFromSelector(action));
  if (nil == object || 0 == keyPaths.count || NULL == action) {
    return;
  }

  for (NSString *keyPath in keyPaths) {
    [self observer:object keyPath:keyPath action:action];
  }
}

- (void)unobserve:(nullable id)object keyPath:(NSString *)keyPath
{
  // unobserve object property
  [self _unobserveWithKeyPath:keyPath observer:object];
}

- (void)unobserve:(nullable id)object
{
  if (nil == object) {
    return;
  }

  [self _unobserve:object];
}

- (void)unobserveAll
{
  [self _unobserveAll];
}

#pragma mark - KVO Callback
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
  /// 取keyPath的监听参数
  NSMutableArray<_FBKVOInfo *> *infos = [_objectInfosMap valueForKey:keyPath];
  if (infos == nil) return;
  
  id newValue = change[NSKeyValueChangeNewKey];
  id oldValue = change[NSKeyValueChangeOldKey];
  NSMutableArray<_FBKVOInfo *> *removeInfo = [NSMutableArray array];
  [infos enumerateObjectsUsingBlock:^(_FBKVOInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if (obj->_observer == nil) {
      [removeInfo addObject:obj];
    } else {
      if (obj->_block) {
        obj->_block(oldValue, newValue);
      } else if (obj->_action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([obj->_observer respondsToSelector:obj->_action]) {
          [obj->_observer performSelector:obj->_action withObject:oldValue withObject:newValue];
        }
#pragma clang diagnostic pop
      }
    }
  }];
  
  if (removeInfo.count > 0) {
    [removeInfo enumerateObjectsUsingBlock:^(_FBKVOInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      [self unobserve:obj->_observer keyPath:obj->_keyPath];
    }];
  }
}
@end


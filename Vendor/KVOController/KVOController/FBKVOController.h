/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 Key provided in the @c change dictionary of @c FBKVONotificationBlock that's value represents the key-path being observed
 */
extern NSString *const FBKVONotificationKeyPathKey;

/**
 @abstract Block called on key-value change notification.
 @param oldValue The oldValue of the change.
 @param newValue The newValue of the chage.
 */
typedef void(^FBKVOControllerChangeBlock)(id _Nullable oldValue, id _Nullable newValue);
/**
 @abstract FBKVOController makes Key-Value Observing simpler and safer.
 @discussion FBKVOController adds support for handling key-value changes with blocks and custom actions, as well as the NSKeyValueObserving callback. Notification will never message a deallocated observer. Observer removal never throws exceptions, and observers are removed implicitly on controller deallocation. FBKVOController is also thread safe. When used in a concurrent environment, it protects observers from possible resurrection and avoids ensuing crash. By default, the controller maintains a strong reference to objects observed.
 */
@interface FBKVOController : NSObject

///--------------------------------------
#pragma mark - Initialize
///--------------------------------------

/**
 @abstract Creates and returns an initialized KVO controller instance.
 @param observer The object notified on key-value change.
 @return The initialized KVO controller instance.
 */
+ (instancetype)controllerWithObserver:(nullable id)observer;

/**
 @abstract Convenience initializer.
 @param observer The object notified on key-value change. The specified observer must support weak references.
 @return The initialized KVO controller instance.
 @discussion By default, KVO controller retains objects observed.
 */
- (instancetype)initWithObserver:(nullable id)observer NS_DESIGNATED_INITIALIZER;

/**
 @abstract Initializes a new instance.

 @warning This method is unavaialble. Please use `initWithObserver:` instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 @abstract Allocates memory and initializes a new instance into it.

 @warning This method is unavaialble. Please use `controllerWithObserver:` instead.
 */
+ (instancetype)new NS_UNAVAILABLE;

///--------------------------------------
#pragma mark - Observe
///--------------------------------------

/**
 The observer notified on key-value change. Specified on initialization.
 */
@property (nullable, nonatomic, weak, readonly) id sender;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPath The key path to observe.
 @param block The block to execute on notification.
 @discussion On key-value change, the specified block is called. In order to avoid retain loops, the block must avoid referencing the KVO controller or an owner thereof. Observing an already observed object key path or nil results in no operation.
 */
- (void)observer:(nullable id)object keyPath:(NSString *)keyPath block:(FBKVOControllerChangeBlock)block;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPath The key path to observe.
 @param action The observer selector called on key-value change.
 @discussion On key-value change, the observer's action selector is called. The selector provided should take the form of -propertyDidChange, -propertyDidChange: or -propertyDidChange:object:, where optional parameters delivered will be KVO change dictionary and object observed. Observing nil or observing an already observed object's key path results in no operation.
 */
- (void)observer:(nullable id)object keyPath:(NSString *)keyPath action:(SEL)action;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPaths The key paths to observe.
 @param block The block to execute on notification.
 @discussion On key-value change, the specified block is called. Inorder to avoid retain loops, the block must avoid referencing the KVO controller or an owner thereof. Observing an already observed object key path or nil results in no operation.
 */
- (void)observer:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths block:(FBKVOControllerChangeBlock)block;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPaths The key paths to observe.
 @param action The observer selector called on key-value change.
 @discussion On key-value change, the observer's action selector is called. The selector provided should take the form of -propertyDidChange, -propertyDidChange: or -propertyDidChange:object:, where optional parameters delivered will be KVO change dictionary and object observed. Observing nil or observing an already observed object's key path results in no operation.
 */
- (void)observer:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths action:(SEL)action;

///--------------------------------------
#pragma mark - Unobserve
///--------------------------------------

/**
 @abstract Unobserve object key path.
 @param object The object to unobserve.
 @param keyPath The key path to observe.
 @discussion If not observing object key path, or unobserving nil, this method results in no operation.
 */
- (void)unobserve:(nullable id)object keyPath:(NSString *)keyPath;

/**
 @abstract Unobserve all object key paths.
 @param object The object to unobserve.
 @discussion If not observing object, or unobserving nil, this method results in no operation.
 */
- (void)unobserve:(nullable id)object;

/**
 @abstract Unobserve all objects.
 @discussion If not observing any objects, this method results in no operation.
 */
- (void)unobserveAll;

@end

NS_ASSUME_NONNULL_END

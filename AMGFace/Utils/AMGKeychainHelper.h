//
//  AMGKeychainHelper.h
//  AMGFace
//
//  Created by CmST0us on 2020/6/8.
//  Copyright © 2020 AMG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMGKeychainHelper : NSObject
+ (void)save:(NSString *)service data:(id)data;
+ (id)load:(NSString *)service;
+ (void)deleteKeyData:(NSString *)service;
@end

NS_ASSUME_NONNULL_END

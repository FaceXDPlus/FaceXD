//
//  NSError+EKMetalKit.h
//  EKMetalKit
//
//  Created by CmST0us on 2019/11/24.
//  Copyright © 2019 eki. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EKMetalKitErrorType) {
    EKMetalKitErrorTypeUnsupport = 1000,
    EKMetalKitErrorTypeInvaildParameter,
    EKMetalKitErrorTypeCreateVisualAreaFailed,
    EKMetalKitErrorTypeCreatePiplineFailed,
};

extern NSErrorDomain const EKMetalKitErrorDomain;

@interface NSError (EKMetalKit)

+ (NSError *)MetalKitErrorWithType:(EKMetalKitErrorType)errorType;

@end

NS_ASSUME_NONNULL_END

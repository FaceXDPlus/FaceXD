//
//  EKMetalContext.h
//  EKMetalKit
//
//  Created by CmST0us on 2019/11/24.
//  Copyright © 2019 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "NSError+EKMetalKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKMetalContext : NSObject

@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) id<MTLLibrary> library;
@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device
                       library:(id<MTLLibrary>)library
                         error:(NSError * _Nullable __autoreleasing * _Nullable)error NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithLibrary:(id<MTLLibrary>)library
                          error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable instancetype)init;

+ (nullable instancetype)defaultContext;

@end

NS_ASSUME_NONNULL_END

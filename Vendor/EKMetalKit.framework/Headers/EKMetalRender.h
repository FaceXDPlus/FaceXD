//
//  EKMetalRender.h
//  EKMetalKit
//
//  Created by CmST0us on 2019/11/24.
//  Copyright © 2019 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKMetalContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKMetalRender : NSObject

@property (nonatomic, readonly) EKMetalContext *context;
@property (nonatomic, readonly) MTKView *renderView;
@property (nonatomic, weak) id<MTKViewDelegate> delegate;

@property (nonatomic, assign) NSInteger frameRate;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(EKMetalContext *)context
                      metalView:(MTKView *)mtkView
                       delegate:(nullable id<MTKViewDelegate>)delegate
                           NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithContext:(EKMetalContext *)context
                      metalView:(MTKView *)mtkView;

- (void)setupRenderWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

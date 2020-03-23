//
//  EKMetalRenderLiveview.h
//  EKMetalKit
//
//  Created by CmST0us on 2019/11/24.
//  Copyright © 2019 eki. All rights reserved.
//

#import "EKSampleBuffer.h"
#import "EKPixelBuffer.h"
#import "EKMetalRender.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, EKMetalRenderLiveviewRotation) {
    EKMetalRenderLiveviewRotationNormal,
    EKMetalRenderLiveviewRotationLeft,
    EKMetalRenderLiveviewRotationRight,
    EKMetalRenderLiveviewRotationUpsideDown,
};
@interface EKMetalRenderLiveview : EKMetalRender

@property (nonatomic, readonly) CGRect videoInsetRect;

@property (nonatomic, assign) EKMetalRenderLiveviewRotation orientation;
@property (nonatomic, assign) BOOL mirror;

- (void)renderSampleBuffer:(EKSampleBuffer *)sampleBuffer;

@end

NS_ASSUME_NONNULL_END

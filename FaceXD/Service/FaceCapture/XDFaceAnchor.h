//
//  XDFaceAnchor.h
//  FaceXD
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XDFaceAnchor : NSObject

@property (nonatomic, readonly) BOOL isTracked;
@property (nonatomic, readonly) simd_float4x4 transform;
@property (nonatomic, readonly) ARFaceGeometry *geometry;
@property (nonatomic, readonly) simd_float4x4 leftEyeTransform;
@property (nonatomic, readonly) simd_float4x4 rightEyeTransform;
@property (nonatomic, readonly) simd_float3 lookAtPoint;
@property (nonatomic, readonly) NSDictionary<ARBlendShapeLocation, NSNumber *> *blendShapes;

+ (instancetype)faceAnchorWithARFaceAnchor:(ARFaceAnchor *)faceAnchor;
+ (instancetype)faceAnchorWith68Points:(NSArray<NSValue *> *)points imageSize:(CGSize)imageSize;
@end

NS_ASSUME_NONNULL_END

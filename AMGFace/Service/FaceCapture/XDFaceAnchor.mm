//
//  XDFaceAnchor.m
//  AMGFace
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDFaceAnchor.h"

@interface XDFaceAnchor ()
@property (nonatomic, assign) BOOL isTracked;
@property (nonatomic, assign) simd_float4x4 transform;
@property (nonatomic, strong) ARFaceGeometry *geometry;
@property (nonatomic, assign) simd_float4x4 leftEyeTransform;
@property (nonatomic, assign) simd_float4x4 rightEyeTransform;
@property (nonatomic, assign) simd_float3 lookAtPoint;
@property (nonatomic, strong) NSDictionary<ARBlendShapeLocation, NSNumber *> *blendShapes;
@end

@implementation XDFaceAnchor

+ (instancetype)faceAnchorWithARFaceAnchor:(ARFaceAnchor *)faceAnchor {
    XDFaceAnchor *anchor = [[XDFaceAnchor alloc] init];
    anchor.transform = faceAnchor.transform;
    anchor.isTracked = faceAnchor.isTracked;
    anchor.geometry = faceAnchor.geometry;
    if (@available(iOS 12.0, *)) {
        anchor.leftEyeTransform = faceAnchor.leftEyeTransform;
        anchor.rightEyeTransform = faceAnchor.rightEyeTransform;
        anchor.lookAtPoint = faceAnchor.lookAtPoint;
    }

    anchor.blendShapes = faceAnchor.blendShapes;
    return anchor;
}
@end

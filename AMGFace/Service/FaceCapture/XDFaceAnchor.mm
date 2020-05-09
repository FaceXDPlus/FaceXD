//
//  XDFaceAnchor.m
//  AMGFace
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDFaceAnchor.h"
#import <opencv2/core.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/highgui.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/calib3d.hpp>
#import <opencv2/video/tracking.hpp>

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

+ (instancetype)faceAnchorWith68Points:(NSArray<NSValue *> *)points imageSize:(CGSize)imageSize {
    XDFaceAnchor *anchor = [[XDFaceAnchor alloc] init];
    
    std::vector<cv::Point2d> imagePoints;
    imagePoints.push_back(cv::Point2d(points[30].CGPointValue.x, points[30].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[8].CGPointValue.x, points[8].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[36].CGPointValue.x, points[36].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[45].CGPointValue.x, points[45].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[48].CGPointValue.x, points[48].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[54].CGPointValue.x, points[54].CGPointValue.y));
    
    std::vector<cv::Point3d> modelPoints;
    modelPoints.push_back(cv::Point3d(0.f, 0.f, 0.f));
    modelPoints.push_back(cv::Point3d(0.f, -330.f, -65.f));
    modelPoints.push_back(cv::Point3d(-255.f, 170.f, -135.f));
    modelPoints.push_back(cv::Point3d(225.f, 170.f, -135.f));
    modelPoints.push_back(cv::Point3d(-150.f, -150.f, -125.f));
    modelPoints.push_back(cv::Point3d(150.f, -150.f, -125.f));
    
    double focalLength = imageSize.width;
    cv::Point2d center = cv::Point2d(imageSize.width / 2, imageSize.height / 2);
    cv::Mat cameraMatrix = (cv::Mat_<double>(3,3) << focalLength, 0, center.x, \
                                                     0, focalLength, center.y, \
                                                     0, 0, 1);
    cv::Mat distCoeffs = cv::Mat::zeros(4, 1, cv::DataType<double>::type);
    cv::Mat rotationVector;
    cv::Mat translationVector;
    
    cv::solvePnP(modelPoints, imagePoints, cameraMatrix, distCoeffs, rotationVector, translationVector, false, cv::SOLVEPNP_ITERATIVE);
    cv::Mat rotation = [[self class] convertToEulerAngle:rotationVector];
    cv::Mat feature = [[self class] processFeatureParameter:points];
    
    SCNMatrix4 rotationMatrix = SCNMatrix4MakeRotation(rotation.at<double>(0, 0), 1, 0, 0);
    rotationMatrix = SCNMatrix4Rotate(rotationMatrix, rotation.at<double>(1, 0), 0, 1, 0);
    rotationMatrix = SCNMatrix4Rotate(rotationMatrix, rotation.at<double>(2, 0), 0, 0, 1);
    anchor.isTracked = YES;
    anchor.transform = SCNMatrix4ToMat4(rotationMatrix);
    anchor.blendShapes = @{
        ARBlendShapeLocationEyeBlinkLeft: @(feature.at<double>(0, 0)),
        ARBlendShapeLocationEyeBlinkRight: @(feature.at<double>(1, 0)),
        ARBlendShapeLocationJawOpen: @(feature.at<double>(2, 0)),
        ARBlendShapeLocationMouthPucker: @(feature.at<double>(3, 0)),
    };
    return anchor;
}

+ (cv::Mat)convertToEulerAngle:(cv::Mat &)rotationVector {
    auto theta = cv::norm(rotationVector, cv::NORM_L2);
    auto w = std::cos(theta * 0.5);
    auto x = std::sin(theta * 0.5) * rotationVector.at<double>(0, 0) / theta;
    auto y = std::sin(theta * 0.5) * rotationVector.at<double>(1, 0) / theta;
    auto z = std::sin(theta * 0.5) * rotationVector.at<double>(2, 0) / theta;
    
    auto xx = x * x;
    auto yy = y * y;
    auto zz = z * z;
    
    auto t0 = 2.0 * (w * x + y * z);
    auto t1 = 1.0 - 2.0 * (xx + yy);
    auto pitch = std::atan2(t0, t1);
    
    auto t2 = 2.0 * (w * y - z * x);
    if (t2 > 1.0) {
        t2 = 1.0;
    } else if (t2 < -1.0) {
        t2 = -1.0;
    }
    auto yaw = std::asin(t2);
    
    auto t3 = 2.0 * (w * z + x * y);
    auto t4 = 1.0 - 2.0 * (yy + zz);
    auto roll = std::atan2(t3, t4);
    
    cv::Mat eular = (cv::Mat_<double>(3, 1, CV_32F) << pitch, yaw, roll);
    return eular;
}

#define kMAKE_POINT(px) (cv::Mat_<double>(2, 1) << points[px].CGPointValue.x, points[px].CGPointValue.y);
+ (cv::Mat)processFeatureParameter:(NSArray<NSValue *> *)points {
    cv::Mat p27 = kMAKE_POINT(27);
    cv::Mat p8 = kMAKE_POINT(8);
    cv::Mat p0 = kMAKE_POINT(0);
    cv::Mat p16 = kMAKE_POINT(16);
    cv::Mat p37 = kMAKE_POINT(37);
    cv::Mat p41 = kMAKE_POINT(41);
    cv::Mat p38 = kMAKE_POINT(38);
    cv::Mat p40 = kMAKE_POINT(40);
    cv::Mat p43 = kMAKE_POINT(43);
    cv::Mat p47 = kMAKE_POINT(47);
    cv::Mat p44 = kMAKE_POINT(44);
    cv::Mat p46 = kMAKE_POINT(46);
    cv::Mat p51 = kMAKE_POINT(51);
    cv::Mat p57 = kMAKE_POINT(57);
    cv::Mat p64 = kMAKE_POINT(64);
    cv::Mat p60 = kMAKE_POINT(60);

    auto d00 = cv::norm(p27 - p8);
    auto d11 = cv::norm(p0 - p16);
    auto dReference = (d00 + d11) / 2;
    
    /// Left Eye
    auto d1 = cv::norm(p37 - p41);
    auto d2 = cv::norm(p38 - p40);
    /// Right Eye
    auto d3 = cv::norm(p43 - p47);
    auto d4 = cv::norm(p44 - p46);
    /// Mouth With
    auto d5 = cv::norm(p51 - p57);
    auto d6 = cv::norm(p60 - p64);
    
    auto leftEyeWid = ((d1 + d2) / (2 * dReference) - 0.02) * 6;
    auto rightEyeWid = ((d3 + d4) / (2 * dReference) - 0.02) * 6;
    auto mouthWid = (d5 / dReference - 0.13) * 1.27 + 0.02;
    auto mouthLen = d6 / dReference;
    
    if (isnan(mouthLen)) {
        mouthLen = 0;
    }
    if (isnan(mouthWid)) {
        mouthWid = 0;
    }
    cv::Mat feature = (cv::Mat_<double>(4, 1) << leftEyeWid, rightEyeWid, mouthWid, mouthLen);
    return feature;
}

@end

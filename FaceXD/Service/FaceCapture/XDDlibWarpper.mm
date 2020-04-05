//
//  XDDlibWarpper.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/21.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dlib/image_processing/frontal_face_detector.h>
#import <dlib/image_processing/shape_predictor.h>
#import <dlib/opencv.h>
#import <opencv2/core.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/highgui.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/calib3d.hpp>
#import <opencv2/video/tracking.hpp>
#import <math.h>
#import "XDDlibWarpper.h"

extern UIImage* MatToUIImage(const cv::Mat& image);
extern void UIImageToMat(const UIImage* image,
                             cv::Mat& m, bool alphaExist = false);

@interface XDDlibFrontalFaceDetector () {
    dlib::frontal_face_detector _detector;
}
@end;
@implementation XDDlibFrontalFaceDetector
- (instancetype)initWithDetector:(dlib::frontal_face_detector)detector {
    self = [super init];
    if (self) {
        _detector = detector;
    }
    return self;
}
@end

#define kDlibFaceLandmarkCount (68)
@interface XDDlibShapePredictor () {
    dlib::shape_predictor _predictor;
}
@end;
@implementation XDDlibShapePredictor
- (instancetype)initWithPredictor:(dlib::shape_predictor)predictor {
    self = [super init];
    if (self) {
        _predictor = predictor;
    }
    return self;
}

- (void)loadModelWithPath:(NSString *)path {
    dlib::deserialize([path cStringUsingEncoding:NSUTF8StringEncoding]) >> _predictor;
}
- (NSArray<NSValue *> *)predictorWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                              rect:(CGRect)rect {
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);

    cv::Mat mat(height, width, CV_8UC4, baseAddress, 0);
    cv::Mat bgrMat;
    cv::cvtColor(mat, bgrMat, CV_BGRA2BGR);
    dlib::cv_image<dlib::bgr_pixel> img(bgrMat);
    
    // convert the face bounds list to dlib format
    NSValue *value = [NSValue valueWithCGRect:rect];
    std::vector<dlib::rectangle> convertedRectangles = [XDDlibShapePredictor convertCGRectValueArray:@[value]];
    
    // for every detected face
    NSMutableArray *array = [[NSMutableArray alloc] init];
    cv::Mat zX = cv::Mat::zeros(kDlibFaceLandmarkCount, 1, CV_32F);
    cv::Mat zY = cv::Mat::zeros(kDlibFaceLandmarkCount, 1, CV_32F);
    
    dlib::rectangle oneFaceRect = convertedRectangles[0];
    // detect all landmarks
    dlib::full_object_detection shape = _predictor(img, oneFaceRect);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
    
    // and draw them into the image (samplebuffer)
    for (unsigned long k = 0; k < shape.num_parts(); k++) {
        dlib::point p = shape.part(k);
        NSValue *v = [NSValue valueWithCGPoint:CGPointMake(p.x(), p.y())];
        [array addObject:v];
    }
    
    return array;
}

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);

        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}

- (XDFaceAnchor *)faceAnchorWithPoints:(NSArray<NSValue *> *)points
                             imageSize:(CGSize)imageSize {
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
    cv::Mat rotation = [self convertToEulerAngle:rotationVector];
    cv::Mat feature = [self processFeatureParameter:points];
    XDFaceAnchor *anchor = [[XDFaceAnchor alloc] init];
//    anchor.headPitch = @(rotation.at<double>(0, 0));
//    anchor.headYaw = @(rotation.at<double>(1, 0));
//    anchor.headRoll = @(rotation.at<double>(2, 0));
//    anchor.leftEyeOpen = @(feature.at<double>(0, 0));
//    anchor.rightEyeOpen = @(feature.at<double>(1, 0));
//    anchor.mouthOpenY = @(feature.at<double>(2, 0));
//    anchor.mouthOpenX = @(feature.at<double>(3, 0));
    return anchor;
}

- (cv::Mat)convertToEulerAngle:(cv::Mat &)rotationVector {
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
- (cv::Mat)processFeatureParameter:(NSArray<NSValue *> *)points {
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
    
    cv::Mat feature = (cv::Mat_<double>(4, 1) << leftEyeWid, rightEyeWid, mouthWid, mouthLen);
    return feature;
}
@end

@implementation XDDlibWarpper
+ (XDDlibFrontalFaceDetector *)getFrontalFaceDetector {
    dlib::frontal_face_detector detector = dlib::get_frontal_face_detector();
    return [[XDDlibFrontalFaceDetector alloc] initWithDetector:detector];
}
+ (XDDlibShapePredictor *)getShapePredictor {
    dlib::shape_predictor predictor = dlib::shape_predictor();
    return [[XDDlibShapePredictor alloc] initWithPredictor:predictor];
}
@end

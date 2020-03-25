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
    cv::KalmanFilter _kalmanFilterX;
    cv::KalmanFilter _kalmanFilterY;
    cv::Mat _controlVector; // U
}
@end;
@implementation XDDlibShapePredictor
- (instancetype)initWithPredictor:(dlib::shape_predictor)predictor {
    self = [super init];
    if (self) {
        _predictor = predictor;
        
        double Q = 1; // 越大，对模型信任度越低，偏向于原始数据
        double R = 10; // 越大，于观测数据信任越低
        
        /// kalmanFilterX
        _kalmanFilterX.init(kDlibFaceLandmarkCount, kDlibFaceLandmarkCount, kDlibFaceLandmarkCount);
        cv::setIdentity(_kalmanFilterX.statePost, cv::Scalar::all(0)); // x
        cv::setIdentity(_kalmanFilterX.measurementMatrix); // H
        cv::setIdentity(_kalmanFilterX.controlMatrix); // B
        cv::setIdentity(_kalmanFilterX.transitionMatrix); // F
        cv::setIdentity(_kalmanFilterX.errorCovPost); // P
        cv::setIdentity(_kalmanFilterX.processNoiseCov, cv::Scalar::all(Q)); // Q
        cv::setIdentity(_kalmanFilterX.measurementNoiseCov, cv::Scalar::all(R)); // R
        /// kalmanFilterY
        _kalmanFilterY.init(kDlibFaceLandmarkCount, kDlibFaceLandmarkCount, kDlibFaceLandmarkCount);
        cv::setIdentity(_kalmanFilterY.statePost, cv::Scalar::all(0)); // x
        cv::setIdentity(_kalmanFilterY.measurementMatrix); // H
        cv::setIdentity(_kalmanFilterY.controlMatrix); // B
        cv::setIdentity(_kalmanFilterY.transitionMatrix); // F
        cv::setIdentity(_kalmanFilterY.errorCovPost); // P
        cv::setIdentity(_kalmanFilterY.processNoiseCov, cv::Scalar::all(Q)); // Q
        cv::setIdentity(_kalmanFilterY.measurementNoiseCov, cv::Scalar::all(R)); // R
        
        _controlVector = cv::Mat::zeros(kDlibFaceLandmarkCount, 1, CV_32F);
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
    
    // and draw them into the image (samplebuffer)
    for (unsigned long k = 0; k < shape.num_parts(); k++) {
        dlib::point p = shape.part(k);
        zX.at<float>((int)k, 0) = (float)p.x();
        zY.at<float>((int)k, 0) = (float)p.y();
    }
    
    
    // Kalman update
    _kalmanFilterX.predict(_controlVector);
    cv::Mat stateX = _kalmanFilterX.correct(zX);
    
    _kalmanFilterY.predict(_controlVector);
    cv::Mat stateY = _kalmanFilterY.correct(zY);
    
    // After update
    for (int i = 0; i < kDlibFaceLandmarkCount; ++i) {
        CGPoint point = CGPointMake(stateX.at<float>(i, 0), stateY.at<float>(i, 0));
        cv::rectangle(mat, cv::Rect(point.x,point.y,4,4), cv::Scalar(255,0,0,255),-1);
        NSValue *v = [NSValue valueWithCGPoint:point];
        [array addObject:v];
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
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

- (void)faceAnchorWithPoints:(NSArray<NSValue *> *)points
                   imageSize:(CGSize)imageSize {
    std::vector<cv::Point2d> imagePoints;
    imagePoints.push_back(cv::Point2d(points[30].CGPointValue.x, points[30].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[8].CGPointValue.x, points[8].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[36].CGPointValue.x, points[36].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[45].CGPointValue.x, points[45].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[1].CGPointValue.x, points[1].CGPointValue.y));
    imagePoints.push_back(cv::Point2d(points[15].CGPointValue.x, points[15].CGPointValue.y));
    
    std::vector<cv::Point3d> modelPoints;
    modelPoints.push_back(cv::Point3d(0.f, 0.f, 0.f));
    modelPoints.push_back(cv::Point3d(0.f, -330.f, -65.f));
    modelPoints.push_back(cv::Point3d(-255.f, 170.f, -135.f));
    modelPoints.push_back(cv::Point3d(225.f, 170.f, -135.f));
    modelPoints.push_back(cv::Point3d(-349.f, 85.f, -300.f));
    modelPoints.push_back(cv::Point3d(349.f, 85.f, -300.f));
    
    double focalLength = imageSize.width;
    cv::Point2d center = cv::Point2d(imageSize.width / 2, imageSize.height / 2);
    cv::Mat cameraMatrix = (cv::Mat_<double>(3,3) << focalLength, 0, center.x, \
                                                     0, focalLength, center.y, \
                                                     0, 0, 1);
    cv::Mat distCoeffs = cv::Mat::zeros(4, 1, cv::DataType<double>::type);
    cv::Mat rotationVector;
    cv::Mat translationVector;
    
    cv::solvePnP(modelPoints, imagePoints, cameraMatrix, distCoeffs, rotationVector, translationVector, false, cv::SOLVEPNP_DLS);
    std::cout << "Rotation:" << std::endl << rotationVector << std::endl;
    std::cout << "Translation:" << std::endl << translationVector << std::endl;
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

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
    for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];
        
        // detect all landmarks
        dlib::full_object_detection shape = _predictor(img, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            CGPoint point = CGPointMake(p.x(), p.y());
            cv::rectangle(mat, cv::Rect(point.x,point.y,4,4), cv::Scalar(255,0,0,255),-1);
            NSValue *v = [NSValue valueWithCGPoint:point];
            [array addObject:v];
        }
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

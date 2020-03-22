//
//  XDDlibWarpper.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/21.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>
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
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    UIImage *image = [self imageFromPixelBuffer:pixelBuffer];
    cv::Mat mat;
    dlib::array2d<dlib::bgr_pixel> img;
    UIImageToMat(image, mat);
    // set_size expects rows, cols format
    img.set_size(height, width);

    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();

        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];

        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;

        position++;
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
    
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
            NSValue *v = [NSValue valueWithCGPoint:point];
            [array addObject:v];
        }
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

- (UIImage*)imageFromPixelBuffer:(CVPixelBufferRef)p
{
    CVImageBufferRef buffer;
    buffer = p;
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return image;
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

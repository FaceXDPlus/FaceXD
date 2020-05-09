//
//  XDDlibWarpper.h
//  AMGFace
//
//  Created by CmST0us on 2020/3/21.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import "XDFaceAnchor.h"
NS_ASSUME_NONNULL_BEGIN

@interface XDDlibFrontalFaceDetector : NSObject
- (instancetype)init NS_UNAVAILABLE;
@end;

@interface XDDlibShapePredictor : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (void)loadModelWithPath:(NSString *)path;
/// 寻找预测点
/// @param pixelBuffer 灰度图pixelBuffer
/// @param rect 目标rect区域
/// @return 目标预测点
- (NSArray<NSValue *> *)predictorWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                              rect:(CGRect)rect;
@end;

@interface XDDlibWarpper : NSObject
+ (XDDlibFrontalFaceDetector *)getFrontalFaceDetector;
+ (XDDlibShapePredictor *)getShapePredictor;
@end

NS_ASSUME_NONNULL_END

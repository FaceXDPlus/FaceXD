//
//  XDOpenCVWarpper.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/21.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <opencv2/core.hpp>
#import "XDOpenCVWarpper.h"

@interface XDCVMatObject ()
@property (nonatomic, assign) cv::Mat mat;
@end
@implementation XDCVMatObject
- (instancetype)initWithMat:(cv::Mat)mat {
    self = [super init];
    if (self) {
        _mat = mat;
    }
    return self;
}
@end

@implementation XDOpenCVWarpper

@end

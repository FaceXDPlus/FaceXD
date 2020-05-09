//
//  XDSimpleKalman.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/11.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDSimpleKalman.h"

@interface XDSimpleKalman ()
@property (nonatomic, assign) CGFloat kalmanQ;
@property (nonatomic, assign) CGFloat kalmanR;
@property (nonatomic, assign) CGFloat kalmanX;
@property (nonatomic, assign) CGFloat kalmanP;
@end

@implementation XDSimpleKalman

+ (instancetype)kalmanWithQ:(CGFloat)q R:(CGFloat)r {
    return [[XDSimpleKalman alloc]initWithQ:q R:r];
}

- (instancetype)initWithQ:(CGFloat)q R:(CGFloat)r {
    self = [super init];
    if (self) {
        _kalmanQ = q;
        _kalmanR = r;
        _kalmanP = 0;
        _kalmanX = 0;
    }
    return self;
}

- (double)calc:(double)x {
    CGFloat XX = self.kalmanX;
    CGFloat PP = self.kalmanP;
    CGFloat K = PP / (PP + _kalmanR);
    XX = XX + K * (x - XX);
    PP = PP - K * PP + _kalmanQ;
    self.kalmanX = XX;
    self.kalmanP = PP;
    return XX;
}

@end

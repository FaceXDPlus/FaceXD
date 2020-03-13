#import <CoreGraphics/CoreGraphics.h>
#import "MPControlValueLinear.h"

@implementation MPControlValueLinear
- (instancetype)initWithOutputMax:(double)outMax
                        outputMin:(double)outMin
                         inputMax:(double)inMax
                         inputMin:(double)inMin {
    self = [super init];
    if (self) {
        _outputMax = outMax;
        _outputMin = outMin;
        _inputMax = inMax;
        _inputMin = inMin;
        _inRange = YES;
        // float 比较 0
        if (ABS(inMax - inMin) < FLT_EPSILON) {
            _k = 0;
        } else {
            _k = (outMax - outMin) / (inMax - inMin);
        }
        _b = outMax - _k * inMax;
    }
    return self;
}

- (instancetype)initWithPoint:(CGPoint)p1 Point2:(CGPoint)p2 {
    self = [super init];
    if (self) {
        _inRange = NO;
        if (ABS(p1.x - p2.x) < FLT_EPSILON) {
            _k = 0;
        } else {
            _k = (p1.y - p2.y) / (p1.x - p2.x);
        }
        _b = p2.y - _k * p2.x;
    }
    return self;
}

- (double)calc:(double)x {
    if (_inRange) {
        x = MIN(_inputMax, x);
        x = MAX(_inputMin, x);
    }
    return _k * x + _b;
}

@end

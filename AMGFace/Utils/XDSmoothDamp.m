//
//  XDSmoothDamp.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/17.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDMathf.h"
#import "XDSmoothDamp.h"

@interface XDSmoothDamp () {
    double _velocity;
}
@end

@implementation XDSmoothDamp

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxSpeed = FLT_MAX;
        _smoothTime = 0.3;
    }
    return self;
}

+ (instancetype)smoothDampWithSmoothTime:(double)smoothTime
                                maxSpeed:(double)maxSpeed {
    XDSmoothDamp *damp = [[XDSmoothDamp alloc] init];
    damp.smoothTime = smoothTime;
    damp.maxSpeed = maxSpeed;
    
    return damp;
}

+ (instancetype)smoothDampWithSmoothTime:(double)smoothTime {
    return [[self class] smoothDampWithSmoothTime:smoothTime
                                         maxSpeed:FLT_MAX];
}

- (double)calc:(double)x {
    return [XDMathf smoothDamp:_currentValue
                        target:x
               currentVelocity:&_velocity
                    smoothTime:_smoothTime
                      maxSpeed:_maxSpeed
                     deltaTime:_deltaTime];
}

@end

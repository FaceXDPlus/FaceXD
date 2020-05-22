//
//  XDMathf.h
//  AMGFace
//
//  Created by CmST0us on 2020/4/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XDMathf : NSObject

+ (double)repeat:(double)t
          length:(double)length;

+ (double)deltaAngle:(double)current
              target:(double)target;

+ (double)smoothDampAngle:(double)current
                   target:(double)target
          currentVelocity:(double *)currentVelocity
               smoothTime:(double)smoothTime
                 maxSpeed:(double)maxSpeed
                deltaTime:(double)deltaTime;

+ (double)smoothDamp:(double)current
              target:(double)target
     currentVelocity:(double *)currentVelocity
          smoothTime:(double)smoothTime
            maxSpeed:(double)maxSpeed
           deltaTime:(double)deltaTime;
    
@end

NS_ASSUME_NONNULL_END

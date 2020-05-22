//
//  XDSmoothDamp.h
//  AMGFace
//
//  Created by CmST0us on 2020/4/17.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDControlValueProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDSmoothDamp : NSObject<XDControlValueProtocol>

/// Set currentValue and deltaTime every calc
@property (nonatomic, assign) double currentValue;
@property (nonatomic, assign) double deltaTime;

@property (nonatomic, assign) double smoothTime;
@property (nonatomic, assign) double maxSpeed;

+ (instancetype)smoothDampWithSmoothTime:(double)smoothTime
                                maxSpeed:(double)maxSpeed;

+ (instancetype)smoothDampWithSmoothTime:(double)smoothTime;

@end

NS_ASSUME_NONNULL_END

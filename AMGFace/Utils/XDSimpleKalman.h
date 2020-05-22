//
//  XDSimpleKalman.h
//  AMGFace
//
//  Created by CmST0us on 2020/4/11.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "XDControlValueProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@interface XDSimpleKalman : NSObject <XDControlValueProtocol>

- (instancetype)initWithQ:(CGFloat)q
                        R:(CGFloat)r;

+ (instancetype)kalmanWithQ:(CGFloat)q R:(CGFloat)r;

@end

NS_ASSUME_NONNULL_END

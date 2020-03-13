#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "MPControlValueProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPControlValueLinear : NSObject<MPControlValueProtocol> {
    double _inputMax;
    double _inputMin;
    double _outputMax;
    double _outputMin;
    
    double _b;
    double _k;
    
    BOOL _inRange;
}

- (instancetype)initWithOutputMax:(double)outMax
                        outputMin:(double)outMin
                         inputMax:(double)inputMax
                         inputMin:(double)inputMin;

- (instancetype)initWithPoint:(CGPoint)p1
                       Point2:(CGPoint)p2;

- (double)calc:(double)x;
@end

NS_ASSUME_NONNULL_END

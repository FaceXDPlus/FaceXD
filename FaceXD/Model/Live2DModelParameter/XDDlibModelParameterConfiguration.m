//
//  XDDlibModelParameterConfiguration.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDDlibModelParameterConfiguration.h"
#import "XDFaceAnchor.h"
#import "XDSimpleKalman.h"
@interface XDDlibModelParameterConfiguration ()
@property (nonatomic, strong) SCNNode *faceNode;
@property (nonatomic, strong) NSDictionary<NSString *, XDSimpleKalman *> *parameterKalman;
@end

@implementation XDDlibModelParameterConfiguration

- (SCNNode *)faceNode {
    if (_faceNode == nil) {
        _faceNode = [SCNNode node];
    }
    return _faceNode;
}

- (instancetype)initWithModel:(LAppModel *)model {
    self = [super initWithModel:model];
    if (self) {
        _parameterKalman = @{
            /// dlib 处理结果可行度不高，传感器噪声大，R需要偏大
            LAppParamAngleY: [XDSimpleKalman kalmanWithQ:0.4 R:100],
            LAppParamAngleX: [XDSimpleKalman kalmanWithQ:0.4 R:100],
            LAppParamAngleZ: [XDSimpleKalman kalmanWithQ:0.4 R:100],
            LAppParamBodyAngleX: [XDSimpleKalman kalmanWithQ:0.4 R:100],
            LAppParamBodyAngleY: [XDSimpleKalman kalmanWithQ:0.4 R:100],
            LAppParamBodyAngleZ: [XDSimpleKalman kalmanWithQ:0.4 R:100],
            LAppParamEyeLOpen: [XDSimpleKalman kalmanWithQ:1 R:10],
            LAppParamEyeROpen: [XDSimpleKalman kalmanWithQ:1 R:10],
            LAppParamEyeBallX: [XDSimpleKalman kalmanWithQ:1 R:10],
            LAppParamEyeBallY: [XDSimpleKalman kalmanWithQ:1 R:10],
            LAppParamMouthOpenY: [XDSimpleKalman kalmanWithQ:1 R:10],
            LAppParamMouthForm: [XDSimpleKalman kalmanWithQ:1 R:10],
        };
    }
    return self;
}

- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor {
    if (!anchor.isTracked) {
        return;
    }
    self.faceNode.simdTransform = anchor.transform;
    
    CGFloat pitch = self.faceNode.eulerAngles.x;
    CGFloat pitchSig = pitch > 0 ? 1 : -1;
    pitch = pitchSig * (M_PI - fabs(pitch));
    pitch = 180.0 / M_PI * pitch;
    pitch -= 12;
    if (pitch < -19) {
        pitch = -19;
    } else if (pitch > 32) {
        pitch = 32;
    }
    self.parameter.headPitch = @(pitch * 2);
    self.parameter.headRoll = @(-180.0 / M_PI * self.faceNode.eulerAngles.z * 2);
    self.parameter.headYaw = @(180.0 / M_PI * self.faceNode.eulerAngles.y * 1.2);
    self.parameter.bodyAngleX = @(self.parameter.headYaw.floatValue / 4);
    self.parameter.bodyAngleY = @(self.parameter.headPitch.floatValue / 2);
    self.parameter.bodyAngleZ = @(self.parameter.headRoll.floatValue / 2);
    NSLog(@"parm: %@", self.parameter);
}

#pragma mark - Interpolation;
- (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to percent:(CGFloat)percent {
    return from + (to - from) * percent;
}

- (void)commit {
    [self.parameterKeyMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *targetValue = [self.parameter valueForKey:obj];
        if (targetValue == nil) {
            targetValue = @(0);
        }
        CGFloat v = targetValue.floatValue;
        XDSimpleKalman *kalman = [self.parameterKalman objectForKey:key];
        if (kalman) {
            v = [kalman calc:v];
        }
        if (targetValue) {
            [self.model setParam:key forValue:@(v)];
        } else {
            [self.model setParam:key forValue:@(0)];
        }
    }];
}
@end

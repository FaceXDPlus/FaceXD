//
//  XDDefaultModelParameterConfiguration.m
//  AMGFace
//
//  Created by CmST0us on 2020/3/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <QuartzCore/CABase.h>
#import "XDDefaultModelParameterConfiguration.h"
#import "XDControlValueLinear.h"
#import "XDSimpleKalman.h"
#import "XDSmoothDamp.h"
#import "NSArray+SIMD.h"

@interface XDDefaultModelParameterConfiguration () {
    CFTimeInterval _lastCommitTimeInterval;
}

@property (nonatomic, strong) SCNNode *faceNode;
@property (nonatomic, strong) SCNNode *leftEyeNode;
@property (nonatomic, strong) SCNNode *rightEyeNode;

@property (nonatomic, strong) XDControlValueLinear *eyeLinearX;
@property (nonatomic, strong) XDControlValueLinear *eyeLinearY;

@property (nonatomic, strong) NSDictionary<NSString *, XDSmoothDamp *> *parameterSmoothDamp;

@property (nonatomic, strong) XDModelParameter *sendParameter;

@end

@implementation XDDefaultModelParameterConfiguration

- (SCNNode *)faceNode {
    if (_faceNode == nil) {
        _faceNode = [SCNNode node];
    }
    return _faceNode;
}

- (SCNNode *)leftEyeNode {
    if (_leftEyeNode == nil) {
        _leftEyeNode = [SCNNode node];
    }
    return _leftEyeNode;
}

- (SCNNode *)rightEyeNode {
    if (_rightEyeNode == nil) {
        _rightEyeNode = [SCNNode node];
    }
    return _rightEyeNode;
}

- (XDModelParameter *)sendParameter {
    if (_sendParameter == nil) {
        _sendParameter = [[XDModelParameter alloc] init];
    }
    return _sendParameter;
}

- (instancetype)initWithModel:(LAppModel *)model {
    self = [super initWithModel:model];
    if (self) {
        _eyeLinearX = [[XDControlValueLinear alloc] initWithOutputMax:[self.model paramMaxValue:LAppParamEyeBallX].doubleValue
                                                            outputMin:[self.model paramMinValue:LAppParamEyeBallX].doubleValue inputMax:45 inputMin:-45];
        _eyeLinearY = [[XDControlValueLinear alloc] initWithOutputMax:[self.model paramMaxValue:LAppParamEyeBallY].doubleValue
                                                            outputMin:[self.model paramMinValue:LAppParamEyeBallY].doubleValue inputMax:45 inputMin:-45];
        _parameterSmoothDamp = @{
            LAppParamAngleY: [XDSmoothDamp smoothDampWithSmoothTime:0.07],
            LAppParamAngleX: [XDSmoothDamp smoothDampWithSmoothTime:0.07],
            LAppParamAngleZ: [XDSmoothDamp smoothDampWithSmoothTime:0.07],
            LAppParamBodyAngleX: [XDSmoothDamp smoothDampWithSmoothTime:0.07],
            LAppParamBodyAngleY: [XDSmoothDamp smoothDampWithSmoothTime:0.07],
            LAppParamBodyAngleZ: [XDSmoothDamp smoothDampWithSmoothTime:0.07],
            LAppParamEyeLOpen: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamEyeROpen: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamEyeLSmile: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamEyeRSmile: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamEyeBallX: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamEyeBallY: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamMouthOpenY: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamMouthForm: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
            LAppParamMouthU: [XDSmoothDamp smoothDampWithSmoothTime:0.03],
        };
    }
    return self;
}

#pragma mark - Getter Setter
- (void)setWorldAlignment:(ARWorldAlignment)worldAlignment {
    if (_worldAlignment == worldAlignment) {
        return;
    }
    _worldAlignment = worldAlignment;
}

- (void)setOrientation:(UIInterfaceOrientation)orientation {
    if (_orientation == orientation) {
        return;
    }
    _orientation = orientation;
}

- (void)setNeedResetBody:(BOOL)needResetBody {
    if (_needResetBody == needResetBody) {
        return;
    }
    _needResetBody = needResetBody;
}

#pragma mark - Public
- (void)beforeUpdateParameter:(XDModelParameter *)parameter {
    
}

- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor {
    [self beforeUpdateParameter:self.parameter];
    self.parameter.isTracked = @(anchor.isTracked);
    if (!anchor.isTracked) {
        [self afterUpdateParameter:self.parameter];
        return;
    }

    self.faceNode.simdTransform = anchor.transform;
    self.leftEyeNode.simdTransform = anchor.leftEyeTransform;
    self.rightEyeNode.simdTransform = anchor.rightEyeTransform;
    
    /*
    SceneKit applies these rotations in the reverse order of the components:
       1. first roll
       2. then yaw
       3. then pitch
    */
    self.parameter.transforms = @{
        @"face.eulerAngles": [NSArray arrayWithFloat3:simd_make_float3(self.faceNode.eulerAngles.x,
                                                                       self.faceNode.eulerAngles.y,
                                                                       self.faceNode.eulerAngles.z)],
        @"face.position": [NSArray arrayWithFloat3:simd_make_float3(self.faceNode.position.x,
                                                                    self.faceNode.position.y,
                                                                    self.faceNode.position.z)],
        @"leftEye.eulerAngles": [NSArray arrayWithFloat3:simd_make_float3(self.leftEyeNode.eulerAngles.x,
                                                                          self.leftEyeNode.eulerAngles.y,
                                                                          self.leftEyeNode.eulerAngles.z)],
        @"rightEye.eulerAngles": [NSArray arrayWithFloat3:simd_make_float3(self.rightEyeNode.eulerAngles.x,
                                                                           self.rightEyeNode.eulerAngles.y,
                                                                           self.rightEyeNode.eulerAngles.z)],
        @"worldAlignment": self.worldAlignment == ARWorldAlignmentCamera ? @"camera" : @"world",
    };
    
    if (self.worldAlignment == ARWorldAlignmentCamera) {
        self.parameter.headPitch = @(-(180 / M_PI) * self.faceNode.eulerAngles.x * 1.3);
        self.parameter.headYaw = @((180 / M_PI) * self.faceNode.eulerAngles.y);
        self.parameter.headRoll = @(-(180 / M_PI) * self.faceNode.eulerAngles.z + 90.0);
        switch (self.orientation) {
            case UIInterfaceOrientationLandscapeRight: {
                self.parameter.headRoll = @(self.parameter.headRoll.floatValue - 90);
            }
                break;
            case UIInterfaceOrientationLandscapeLeft: {
                CGFloat headRoll = (M_PI - ABS(self.faceNode.eulerAngles.z)) * (self.faceNode.eulerAngles.z > 0 ? -1 : 1);
                self.parameter.headRoll = @(-(180 / M_PI) * headRoll);
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown: {
                self.parameter.headRoll = @(self.parameter.headRoll.floatValue - 180);
            }
                break;
            default:
                break;
        }
    } else if (self.worldAlignment == ARWorldAlignmentGravity) {
        self.parameter.headPitch = @(-(180 / M_PI) * self.faceNode.eulerAngles.x * 1.3);
        self.parameter.headYaw = @((180 / M_PI) * self.faceNode.eulerAngles.y);
        self.parameter.headRoll = @(-(180 / M_PI) * self.faceNode.eulerAngles.z);
    }

    SCNVector3 position = self.faceNode.position;
    float distance = sqrt((position.x * position.x)+(position.y * position.y)+(position.z * position.z));
    
    if(self.needResetBody == YES){
        self.needResetBody = NO;
        self.distanceY = distance;
        self.distanceZ = position;
    }
    
    
    self.parameter.bodyAngleX = @(self.parameter.headYaw.floatValue / 4);
    self.parameter.bodyAngleY = @(atan((distance - self.distanceY)/0.5) * 30);
    self.parameter.bodyAngleZ = @(- atan((self.distanceZ.y-position.y)/0.5) * 30);
    
    self.parameter.eyeLOpen = @(1 - anchor.blendShapes[ARBlendShapeLocationEyeBlinkLeft].floatValue * 1.3);
    self.parameter.eyeROpen = @(1 - anchor.blendShapes[ARBlendShapeLocationEyeBlinkRight].floatValue * 1.3);
    
    CGFloat lookUpL = anchor.blendShapes[ARBlendShapeLocationEyeLookUpLeft].floatValue;
    CGFloat lookDownL = anchor.blendShapes[ARBlendShapeLocationEyeLookDownLeft].floatValue;
    CGFloat lookInL = anchor.blendShapes[ARBlendShapeLocationEyeLookInLeft].floatValue;
    CGFloat lookOutL = anchor.blendShapes[ARBlendShapeLocationEyeLookOutLeft].floatValue;
    CGFloat lookUpR = anchor.blendShapes[ARBlendShapeLocationEyeLookUpRight].floatValue;
    CGFloat lookDownR = anchor.blendShapes[ARBlendShapeLocationEyeLookDownRight].floatValue;
    CGFloat lookInR = anchor.blendShapes[ARBlendShapeLocationEyeLookInRight].floatValue;
    CGFloat lookOutR = anchor.blendShapes[ARBlendShapeLocationEyeLookOutRight].floatValue;
    CGFloat xEyeL = lookOutL - lookInL;
    CGFloat xEyeR = lookInR - lookOutR;
    CGFloat yEyeL = lookUpL - lookDownL;
    CGFloat yEyeR = lookUpR - lookDownR;
    
    if (@available(iOS 12.0, *)) {
        self.parameter.eyeX = @(anchor.lookAtPoint.x * 2);
        self.parameter.eyeY = @(anchor.lookAtPoint.y * 2);
    } else {
        self.parameter.eyeX = @((xEyeL + xEyeR) / 2);
        self.parameter.eyeY = @((yEyeL + yEyeR) / 2);
    }
    
    CGFloat innerUp = anchor.blendShapes[ARBlendShapeLocationBrowInnerUp].floatValue;
    CGFloat outerUpL = anchor.blendShapes[ARBlendShapeLocationBrowOuterUpLeft].floatValue;
    CGFloat outerUpR = anchor.blendShapes[ARBlendShapeLocationBrowOuterUpRight].floatValue;
    CGFloat downL = anchor.blendShapes[ARBlendShapeLocationBrowDownLeft].floatValue;
    CGFloat downR = anchor.blendShapes[ARBlendShapeLocationBrowDownRight].floatValue;
    
    self.parameter.eyeBrowYL = @(outerUpL);
    self.parameter.eyeBrowYR = @(outerUpR);
    
    self.parameter.eyeBrowAngleL = @( 0 - (downL - 1/2) + 1/6);
    self.parameter.eyeBrowAngleR = @( 0 - (downR - 1/2) + 1/6);
    
    self.parameter.eyeBrowLForm = @(17 * (innerUp - outerUpL) - downL - 2);
    self.parameter.eyeBrowRForm = @(17 * (innerUp - outerUpR) - downR - 2);
    
    CGFloat MouthPucker = anchor.blendShapes[ARBlendShapeLocationMouthPucker].floatValue;
    
    CGFloat mouthLeft = anchor.blendShapes[ARBlendShapeLocationMouthFrownLeft].floatValue;
    CGFloat mouthRight = anchor.blendShapes[ARBlendShapeLocationMouthFrownRight].floatValue;
    CGFloat mouthSmileLeft = anchor.blendShapes[ARBlendShapeLocationMouthSmileLeft].floatValue;
    CGFloat mouthSmileRight = anchor.blendShapes[ARBlendShapeLocationMouthSmileRight].floatValue;
    CGFloat mouthForm = ((0 - (mouthLeft - mouthSmileLeft + mouthRight - mouthSmileRight) / 2)  + 0.5);
    mouthForm = mouthForm - MouthPucker * 2;
    
    CGFloat mouthFunnel = anchor.blendShapes[ARBlendShapeLocationMouthFunnel].floatValue;
    
    self.parameter.eyeLSmile = @(mouthSmileLeft * 2);
    self.parameter.eyeRSmile = @(mouthSmileRight * 2);
    
    self.parameter.mouthForm = @(mouthForm);
    self.parameter.mouthU = @(mouthFunnel);
    self.parameter.mouthOpenY = @(anchor.blendShapes[ARBlendShapeLocationJawOpen].floatValue * 1.3);
    
    if (self.appendBlendShapes) {
        self.parameter.blendShapes = anchor.blendShapes;
    } else {
        self.parameter.blendShapes = nil;        
    }
    
    [self afterUpdateParameter:self.parameter];
}

- (void)afterUpdateParameter:(XDModelParameter *)parameter {
    self.sendParameter = self.parameter;
}

- (void)commit {
    CFTimeInterval currentTime = CACurrentMediaTime();
    [[self class].parameterKeyMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *targetValue = [self.parameter valueForKey:obj];
        NSNumber *currentValue = [self.model paramValue:key];
        if (targetValue == nil) {
            targetValue = @(0);
        }
        CGFloat smooth = targetValue.floatValue;
        XDSmoothDamp *smoothDamp = [self.parameterSmoothDamp objectForKey:key];
        if (smoothDamp) {
            smoothDamp.deltaTime = currentTime - _lastCommitTimeInterval;
            smoothDamp.currentValue = [currentValue doubleValue];
            smooth = [smoothDamp calc:smooth];
        }
        
        if (targetValue) {
            [self.model setParam:key forValue:@(smooth)];
        } else {
            [self.model setParam:key forValue:@(0)];
        }
    }];
    _lastCommitTimeInterval = currentTime;
}


@end

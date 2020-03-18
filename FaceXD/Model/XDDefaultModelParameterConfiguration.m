//
//  XDDefaultModelParameterConfiguration.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDDefaultModelParameterConfiguration.h"
#import "XDControlValueLinear.h"

@interface XDDefaultModelParameterConfiguration ()
@property (nonatomic, weak) SCNNode *leftEyeNode;
@property (nonatomic, weak) SCNNode *rightEyeNode;
@property (nonatomic, weak) SCNNode *faceNode;
@property (nonatomic, weak) ARFaceAnchor *faceAnchor;

@property (nonatomic, strong) XDControlValueLinear *eyeLinearX;
@property (nonatomic, strong) XDControlValueLinear *eyeLinearY;
@end

@implementation XDDefaultModelParameterConfiguration

- (instancetype)initWithModel:(LAppModel *)model {
    self = [super initWithModel:model];
    if (self) {
        _eyeLinearX = [[XDControlValueLinear alloc] initWithOutputMax:[self.model paramMaxValue:LAppParamEyeBallX].doubleValue
                                                            outputMin:[self.model paramMinValue:LAppParamEyeBallX].doubleValue inputMax:45 inputMin:-45];
        _eyeLinearY = [[XDControlValueLinear alloc] initWithOutputMax:[self.model paramMaxValue:LAppParamEyeBallY].doubleValue
                                                            outputMin:[self.model paramMinValue:LAppParamEyeBallY].doubleValue inputMax:45 inputMin:-45];
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

#pragma mark - Public
- (void)updateParameterWithFaceAnchor:(ARFaceAnchor *)anchor
                             faceNode:(SCNNode *)faceNode
                          leftEyeNode:(SCNNode *)leftEyeNode
                         rightEyeNode:(SCNNode *)rightEyeNode {
    self.faceNode = faceNode;
    self.faceAnchor = anchor;
    self.leftEyeNode = leftEyeNode;
    self.rightEyeNode = rightEyeNode;
    
    if (self.worldAlignment == ARWorldAlignmentCamera) {
        self.parameter.headPitch = @(-(180 / M_PI) * self.faceNode.eulerAngles.x * 1.3);
        self.parameter.headYaw = @((180 / M_PI) * self.faceNode.eulerAngles.y);
        self.parameter.headRoll = @(-(180 / M_PI) * self.faceNode.eulerAngles.z + 90.0);
    } else if (self.worldAlignment == ARWorldAlignmentGravity) {
        self.parameter.headPitch = @(-(180 / M_PI) * self.faceNode.eulerAngles.x * 1.3);
        self.parameter.headYaw = @((180 / M_PI) * self.faceNode.eulerAngles.y);
        self.parameter.headRoll = @(-(180 / M_PI) * self.faceNode.eulerAngles.z);
    }

    switch (self.orientation) {
        case UIInterfaceOrientationLandscapeRight:
            self.parameter.headRoll = self.parameter.headRoll - 90;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.parameter.headRoll = - asin(self.faceAnchor.transform.columns[1].x) * 40;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.parameter.headRoll = self.parameter.headRoll - 180;
            break;
        default:
            break;
    }
    
    self.parameter.bodyAngleX = @(self.parameter.headYaw.floatValue / 4);
    self.parameter.bodyAngleY = @(self.parameter.headPitch.floatValue / 2);
    self.parameter.bodyAngleZ = @(self.parameter.headRoll.floatValue / 2);

    self.parameter.eyeLOpen = @(1 - self.faceAnchor.blendShapes[ARBlendShapeLocationEyeBlinkLeft].floatValue * 1.3);
    self.parameter.eyeROpen = @(1 - self.faceAnchor.blendShapes[ARBlendShapeLocationEyeBlinkRight].floatValue * 1.3);
    self.parameter.eyeX = @([self.eyeLinearX calc:(180 / M_PI) * self.leftEyeNode.eulerAngles.y]);
    self.parameter.eyeY = @(-[self.eyeLinearY calc:(180 / M_PI) * self.leftEyeNode.eulerAngles.x]);
    self.parameter.mouthOpenY = @(self.faceAnchor.blendShapes[ARBlendShapeLocationJawOpen].floatValue * 1.8);
    
    CGFloat innerUp = self.faceAnchor.blendShapes[ARBlendShapeLocationBrowInnerUp].floatValue;
    CGFloat outerUpL = self.faceAnchor.blendShapes[ARBlendShapeLocationBrowOuterUpLeft].floatValue;
    CGFloat outerUpR = self.faceAnchor.blendShapes[ARBlendShapeLocationBrowOuterUpRight].floatValue;
    CGFloat downL = self.faceAnchor.blendShapes[ARBlendShapeLocationBrowDownLeft].floatValue;
    CGFloat downR = self.faceAnchor.blendShapes[ARBlendShapeLocationBrowDownRight].floatValue;
    self.parameter.eyeBrowYL = @((innerUp + outerUpL) / 2);
    self.parameter.eyeBrowYR = @((innerUp + outerUpR) / 2);
    self.parameter.eyeBrowAngleL = @(17 * (innerUp - outerUpL) - downL - 2.5);
    self.parameter.eyeBrowAngleR = @(17 * (innerUp - outerUpR) - downR - 2.5);
    CGFloat mouthFunnel = self.faceAnchor.blendShapes[ARBlendShapeLocationMouthFunnel].floatValue;
    CGFloat mouthLeft = self.faceAnchor.blendShapes[ARBlendShapeLocationMouthFrownLeft].floatValue;
    CGFloat mouthRight = self.faceAnchor.blendShapes[ARBlendShapeLocationMouthFrownRight].floatValue;
    CGFloat mouthSmileLeft = self.faceAnchor.blendShapes[ARBlendShapeLocationMouthSmileLeft].floatValue;
    CGFloat mouthSmileRight = self.faceAnchor.blendShapes[ARBlendShapeLocationMouthSmileRight].floatValue;
    CGFloat mouthForm = 0 - (mouthLeft - mouthSmileLeft + mouthRight - mouthSmileRight) / 2 * 8 - 1 / 3;
    if(mouthForm < 0){
        mouthForm = mouthForm - mouthFunnel;
    }
    self.parameter.mouthForm = @(mouthForm);
    
    
}


@end

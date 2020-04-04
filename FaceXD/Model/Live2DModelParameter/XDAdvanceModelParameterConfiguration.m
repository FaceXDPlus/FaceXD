//
//  XDAdvanceModelParameterConfiguration.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/18.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDAdvanceModelParameterConfiguration.h"

@implementation XDAdvanceModelParameterConfiguration
- (void)updateParameterWithFaceAnchor:(ARFaceAnchor *)anchor
                             faceNode:(SCNNode *)faceNode
                          leftEyeNode:(SCNNode *)leftEyeNode
                         rightEyeNode:(SCNNode *)rightEyeNode {
    [super updateParameterWithFaceAnchor:anchor
                                faceNode:faceNode
                             leftEyeNode:leftEyeNode
                            rightEyeNode:rightEyeNode];
    self.parameter.blendShapes = anchor.blendShapes;
}
@end

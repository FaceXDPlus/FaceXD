//
//  XDAdvanceModelParameterConfiguration.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/18.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDAdvanceModelParameterConfiguration.h"

@implementation XDAdvanceModelParameterConfiguration
- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor {
    [super updateParameterWithFaceAnchor:anchor];
    self.parameter.blendShapes = anchor.blendShapes;
}
@end

//
//  XDFaceAnchor.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDFaceAnchor.h"

@implementation XDFaceAnchor
- (NSString *)description {
    return [NSString stringWithFormat:@"headPitch: %@\nheadYaw: %@\nheadRoll: %@\nleftEyeOpen: %@\nrightEyeOpen: %@\nmouthOpenY: %@\nmouthOpenX: %@", self.headPitch, self.headYaw, self.headRoll, self.leftEyeOpen, self.rightEyeOpen, self.mouthOpenY, self.mouthOpenX];
}
@end

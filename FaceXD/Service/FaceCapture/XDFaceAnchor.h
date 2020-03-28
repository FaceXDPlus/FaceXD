//
//  XDFaceAnchor.h
//  FaceXD
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XDFaceAnchor : NSObject
@property (nonatomic, strong, nullable) NSNumber *headPitch;
@property (nonatomic, strong, nullable) NSNumber *headYaw;
@property (nonatomic, strong, nullable) NSNumber *headRoll;

@property (nonatomic, strong, nullable) NSNumber *leftEyeOpen;
@property (nonatomic, strong, nullable) NSNumber *rightEyeOpen;

@property (nonatomic, strong, nullable) NSNumber *mouthOpenY;
@property (nonatomic, strong, nullable) NSNumber *mouthOpenX;
@end

NS_ASSUME_NONNULL_END

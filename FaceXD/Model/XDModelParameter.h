//
//  XDModelParameter.h
//  FaceXD
//
//  Created by CmST0us on 2020/3/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ARKit/ARKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface XDModelParameter : NSObject<NSCopying>

@property (nonatomic, copy, nullable) NSNumber *headPitch;
@property (nonatomic, copy, nullable) NSNumber *headYaw;
@property (nonatomic, copy, nullable) NSNumber *headRoll;
@property (nonatomic, copy, nullable) NSNumber *bodyAngleX;
@property (nonatomic, copy, nullable) NSNumber *bodyAngleY;
@property (nonatomic, copy, nullable) NSNumber *bodyAngleZ;
@property (nonatomic, copy, nullable) NSNumber *eyeLOpen;
@property (nonatomic, copy, nullable) NSNumber *eyeROpen;
@property (nonatomic, copy, nullable) NSNumber *eyeBrowYL;
@property (nonatomic, copy, nullable) NSNumber *eyeBrowYR;
@property (nonatomic, copy, nullable) NSNumber *eyeBrowAngleL;
@property (nonatomic, copy, nullable) NSNumber *eyeBrowAngleR;
@property (nonatomic, copy, nullable) NSNumber *eyeX;
@property (nonatomic, copy, nullable) NSNumber *eyeY;
@property (nonatomic, copy, nullable) NSNumber *mouthOpenY;
@property (nonatomic, copy, nullable) NSNumber *mouthForm;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *blendShapes;

@property (nonatomic, copy, nullable) NSString *timestamp;

- (NSDictionary *)parameterValueDictionary;
@end

NS_ASSUME_NONNULL_END

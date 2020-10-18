//
//  XDDefaultModelParameterConfiguration.h
//  AMGFace
//
//  Created by CmST0us on 2020/3/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDModelParameterConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDDefaultModelParameterConfiguration : XDModelParameterConfiguration

@property (nonatomic, assign) ARWorldAlignment worldAlignment;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) BOOL needResetBody;
@property (nonatomic, assign) BOOL appendBlendShapes;
@property (nonatomic, assign) float distanceY;
@property (nonatomic, assign) SCNVector3 distanceZ;

@end

NS_ASSUME_NONNULL_END

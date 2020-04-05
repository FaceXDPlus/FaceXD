//
//  XDDefaultModelParameterConfiguration.h
//  FaceXD
//
//  Created by CmST0us on 2020/3/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDModelParameterConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDDefaultModelParameterConfiguration : XDModelParameterConfiguration

@property (nonatomic, assign) ARWorldAlignment worldAlignment;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

@property (nonatomic, assign) BOOL interpolation;
/// 数据间隔, 如果数据以30Hz更新，则设置(1.0 / 30.0)
@property (nonatomic, assign) NSTimeInterval frameInterval;
@end

NS_ASSUME_NONNULL_END

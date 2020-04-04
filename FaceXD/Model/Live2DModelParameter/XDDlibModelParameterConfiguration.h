//
//  XDDlibModelParameterConfiguration.h
//  FaceXD
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDModelParameterConfigration.h"

NS_ASSUME_NONNULL_BEGIN

@class XDFaceAnchor;
@interface XDDlibModelParameterConfiguration : XDModelParameterConfigration
@property (nonatomic, assign) BOOL interpolation;
/// 数据间隔, 如果数据以30Hz更新，则设置(1.0 / 30.0)
@property (nonatomic, assign) NSTimeInterval frameInterval;

- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor;
@end

NS_ASSUME_NONNULL_END

//
//  XDDlibModelParameterConfiguration.h
//  FaceXD
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDModelParameterConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class XDFaceAnchor;
@interface XDDlibModelParameterConfiguration : XDModelParameterConfiguration

- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor;
@end

NS_ASSUME_NONNULL_END

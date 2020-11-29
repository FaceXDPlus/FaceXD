//
//  XDLive2DCaptureARKitViewModel.h
//  AMGFace
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
#import "XDLive2DCaptureViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface XDLive2DCaptureARKitViewModel : XDLive2DCaptureViewModel
@property (nonatomic, assign) ARWorldAlignment worldAlignment;
@property (nonatomic, assign) BOOL needResetBody;

@end

NS_ASSUME_NONNULL_END

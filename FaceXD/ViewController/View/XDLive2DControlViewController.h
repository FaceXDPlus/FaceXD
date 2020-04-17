//
//  XDLive2DControlViewController.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XDLive2DCaptureViewModel;
@interface XDLive2DControlViewController : UIViewController
@property (nonatomic, readonly) BOOL needShowCamera;

- (void)attachCaptureViewModel:(XDLive2DCaptureViewModel *)captureViewModel;

@end

NS_ASSUME_NONNULL_END

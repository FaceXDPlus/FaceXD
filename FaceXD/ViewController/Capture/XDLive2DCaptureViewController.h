//
//  XDLive2DCaptureViewController.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XDLive2DCaptureViewModel.h"
NS_ASSUME_NONNULL_BEGIN
@class XDLive2DCaptureViewModel;
@interface XDLive2DCaptureViewController : UIViewController
@property (nonatomic, readonly) XDLive2DCaptureViewModel *viewModel;
@property (nonatomic, readonly) MTKView *liveview;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithModelName:(NSString *)modelName;

- (void)resetModel;
@end

NS_ASSUME_NONNULL_END

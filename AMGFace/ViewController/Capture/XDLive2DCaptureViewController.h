//
//  XDLive2DCaptureViewController.h
//  AMGFace
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
- (void)layoutCameraPreviewViewWithPoint:(CGPoint)point;
@end

NS_ASSUME_NONNULL_END

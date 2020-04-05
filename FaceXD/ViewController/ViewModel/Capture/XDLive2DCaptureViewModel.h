//
//  XDLive2DCaptureViewModel.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XDLive2DCaptureViewModel : NSObject

@property (nonatomic, readonly) BOOL isCapturing;

- (void)startCapture NS_REQUIRES_SUPER;
- (void)stopCapture NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END

//
//  XDLive2DControlViewModel.h
//  AMGFace
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDWebSocketService.h"
NS_ASSUME_NONNULL_BEGIN

@class XDLive2DCaptureViewModel;
@interface XDLive2DControlViewModel : NSObject
@property (nonatomic, readonly) XDWebSocketService *webSocketService;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, copy) NSString *port;
- (NSError *)connect;
- (void)disconnect;

@property (nonatomic, readonly) NSString *appVersion;

@property (nonatomic, readonly) XDLive2DCaptureViewModel *captureViewModel;

- (void)startCapture;
- (void)stopCapture;

- (void)attachLive2DCaptureViewModel:(XDLive2DCaptureViewModel *)captureViewModel;
@end

NS_ASSUME_NONNULL_END

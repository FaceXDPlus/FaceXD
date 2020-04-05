//
//  XDLive2DCaptureViewModel.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDModelParameterConfiguration.h"
#import "XDFaceAnchor.h"
NS_ASSUME_NONNULL_BEGIN

@class XDLive2DCaptureViewModel;
@protocol XDLive2DCaptureViewModelDelegate <NSObject>
- (void)viewModel:(XDLive2DCaptureViewModel *)viewModel didOutputCameraPreview:(CMSampleBufferRef)sampleBuffer;
- (void)viewModel:(XDLive2DCaptureViewModel *)viewModel didOutputFaceAnchor:(XDFaceAnchor *)faceAnchor;
@end

@interface XDLive2DCaptureViewModel : NSObject
@property (nonatomic, weak) id<XDLive2DCaptureViewModelDelegate> delegate;
@property (nonatomic, readonly) BOOL isCapturing;

@property (nonatomic, assign) BOOL advanceMode;

- (void)startCapture NS_REQUIRES_SUPER;
- (void)stopCapture NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END

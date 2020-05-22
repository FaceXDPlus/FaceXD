//
//  XDLive2DCaptureARKitViewModel.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDLive2DCaptureARKitViewModel.h"
#import "XDUserDefineKeys.h"

@interface XDLive2DCaptureARKitViewModel () <ARSessionDelegate>
@property (nonatomic, strong) ARSession * arSession;
@property (nonatomic, strong) dispatch_queue_t arSessionDelegateQueue;
@end


@implementation XDLive2DCaptureARKitViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        NSNumber *alignmentNumber = [userDefault objectForKey:XDUserDefineKeySubmitCameraAlignment];
        if (alignmentNumber == nil) {
            alignmentNumber = @(YES);
            [userDefault setObject:alignmentNumber forKey:XDUserDefineKeySubmitCameraAlignment];
        }
        BOOL relative = alignmentNumber.boolValue;
        _worldAlignment = relative ? ARWorldAlignmentCamera : ARWorldAlignmentGravity;
        _arSessionDelegateQueue = dispatch_queue_create("XDLive2DCaptureARKitViewModel::SessionDelegateQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)startCapture {
    [self setupARSession];
    [super startCapture];
}

- (void)stopCapture {
    [self.arSession pause];
    [super stopCapture];
}

- (void)setWorldAlignment:(ARWorldAlignment)worldAlignment {
    if (self.worldAlignment == worldAlignment) {
        return;
    }
    _worldAlignment = worldAlignment;
    if (self.isCapturing) {
        [self stopCapture];
        [self startCapture];
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(worldAlignment) forKey:XDUserDefineKeySubmitCameraAlignment];
}

#pragma mark - Private
- (void)setupARSession {
    self.arSession = [[ARSession alloc] init];
    self.arSession.delegateQueue = self.arSessionDelegateQueue;
    ARFaceTrackingConfiguration *faceTracking = [[ARFaceTrackingConfiguration alloc] init];
    faceTracking.worldAlignment = self.worldAlignment;
    
    if (@available(iOS 11.3, *)) {
        __block ARVideoFormat *format = nil;
        [[ARFaceTrackingConfiguration supportedVideoFormats] enumerateObjectsUsingBlock:^(ARVideoFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.framesPerSecond == 60 &&
                fabs(obj.imageResolution.height - 720) < 1e-6) {
                format = obj;
            }
        }];
        if (format != nil) {
            faceTracking.videoFormat = format;
        }
    }
    
    self.arSession.delegate = self;
    [self.arSession runWithConfiguration:faceTracking];
}

#pragma mark - Delegate
- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
    CMVideoFormatDescriptionRef format = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault,
                                                 frame.capturedImage,
                                                 &format);
    CMSampleTimingInfo timing;
    timing.decodeTimeStamp = kCMTimeInvalid;
    timing.presentationTimeStamp = kCMTimeInvalid;
    timing.duration = kCMTimeInvalid;
    CMSampleBufferRef sampleBuffer = NULL;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                       frame.capturedImage,
                                       true,
                                       NULL,
                                       NULL,
                                       format,
                                       &timing,
                                       &sampleBuffer);
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(viewModel:didOutputCameraPreview:)]) {
        [self.delegate viewModel:self didOutputCameraPreview:sampleBuffer];
    }
    
    CFRelease(sampleBuffer);
    CFRelease(format);
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<__kindof ARAnchor *> *)anchors {
    if (anchors &&
        anchors.count > 0) {
        XDFaceAnchor *anchor = [XDFaceAnchor faceAnchorWithARFaceAnchor:anchors[0]];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(viewModel:didOutputFaceAnchor:)]) {
            [self.delegate viewModel:self didOutputFaceAnchor:anchor];
        }
    }
}

@end

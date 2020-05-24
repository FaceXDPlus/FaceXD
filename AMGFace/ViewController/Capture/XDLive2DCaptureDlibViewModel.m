//
//  XDLive2DCaptureDlibViewModel.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <CameraKit/CameraKit.h>
#import "XDLive2DCaptureDlibViewModel.h"
#import "XDDlibWarpper.h"

@interface XDLive2DCaptureDlibViewModel () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) CKSession *cameraSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *faceOutput;
@property (atomic, strong) AVMetadataObject *currentMetadataObject;

@property (nonatomic, strong) dispatch_queue_t videoOutputQueue;
@property (nonatomic, strong) dispatch_queue_t faceOutputQueue;

@property (nonatomic, strong) NSTimer *faceCheckTimer;
@property (nonatomic, assign) NSUInteger faceCheckCount;

@property (nonatomic, strong) XDDlibShapePredictor *shapePredictor;
@end

@implementation XDLive2DCaptureDlibViewModel

- (void)dealloc {
    [self stopCapture];
    [self.faceCheckTimer invalidate];
    self.faceCheckTimer = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _shapePredictor = [XDDlibWarpper getShapePredictor];
        [_shapePredictor loadModelWithPath:[[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"]];
        _videoOutputQueue = dispatch_queue_create("VideoOutputQueue", DISPATCH_QUEUE_SERIAL);
        _faceOutputQueue = dispatch_queue_create("FaceOutputQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Override Method
- (void)startCapture {
    __weak typeof(self) weakSelf = self;
    self.cameraSession = [[CKSession alloc] initWithMultiCameraSupport:NO];
    [self.cameraSession startSessionWithConfigBlock:^(CKSession * _Nonnull session, CKSessionConfiguration * _Nonnull config) {
        NSNumber *deviceID = @(CKCaptureDeviceTypeBuiltInWideAngleCamera | CKCaptureDevicePositionFront);
        config.videoDevice = @[deviceID];
        config.sessionPresent = AVCaptureSessionPreset1280x720;
        
        weakSelf.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [weakSelf.videoOutput setVideoSettings:@{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
        }];
        
        [weakSelf.videoOutput setSampleBufferDelegate:weakSelf queue:weakSelf.videoOutputQueue];
        [config addOutput:weakSelf.videoOutput forDevice:deviceID];
        
        weakSelf.faceOutput = [[AVCaptureMetadataOutput alloc] init];
        [weakSelf.faceOutput setMetadataObjectsDelegate:weakSelf queue:weakSelf.faceOutputQueue];
        [config addOutput:weakSelf.faceOutput forDevice:deviceID];
    } completion:^(NSError * _Nullable error) {
        if (error != nil) {
            [weakSelf stopCapture];
            return;
        }
        
        CKCaptureDevice *device = [weakSelf.cameraSession.currentVideoDevice firstObject];
        NSInteger exceptFrameRate = 60;
        NSInteger exceptResolution = 720;
        OSType exceptFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        AVCaptureDeviceFormat *hitFormat = nil;
        if (device) {
            if ([device.captureDevice lockForConfiguration:nil]) {
                for (AVCaptureDeviceFormat *format in device.captureDevice.formats) {
                    CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
                    if (dimension.height != exceptResolution) {
                        continue;
                    }
                    if (CMFormatDescriptionGetMediaSubType(format.formatDescription) != exceptFormat) {
                        continue;
                    }
                    
                    for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                        if (range.maxFrameRate >= exceptFrameRate) {
                            hitFormat = format;
                        }
                    }
                }
                if (hitFormat) {
                    [device.captureDevice setActiveFormat:hitFormat];
                    [device.captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 60)];
                    [device.captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 60)];
                }
                [device.captureDevice unlockForConfiguration];
            }
        }
        
        AVCaptureConnection *connection = [weakSelf.videoOutput.connections firstObject];
        if (connection) {
            __block UIInterfaceOrientation orientation;
            dispatch_sync(dispatch_get_main_queue(), ^{
                orientation = [UIApplication sharedApplication].statusBarOrientation;
            });
            if (orientation == UIInterfaceOrientationLandscapeLeft) {
                connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            } else if (orientation == UIInterfaceOrientationLandscapeRight) {
                connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            } else {
                connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            }
            [connection setVideoMirrored:YES];
            [weakSelf.faceOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
        }
    }];
    
    self.faceCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        weakSelf.faceCheckCount = 0;
    }];
    [self bindData];
    [super startCapture];
}

- (void)stopCapture {
    [self.cameraSession stopSessionWithCompletion:^(NSError * _Nullable error) {
        
    }];
    [self.faceCheckTimer invalidate];
    self.faceCheckTimer = nil;
    [self unBindData];
    [super stopCapture];
}

- (void)bindData {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)unBindData {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Handler
- (void)handleOrientationChange {
    AVCaptureConnection *connection = [self.videoOutput.connections firstObject];
    if (connection) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        } else {
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
        [connection setVideoMirrored:YES];
    }
}

#pragma mark - Delegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    CGRect faceBoundsInImage = [output transformedMetadataObjectForMetadataObject:self.currentMetadataObject connection:connection].bounds;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    NSArray<NSValue *> *points = [self.shapePredictor predictorWithCVPixelBuffer:pixelBuffer rect:faceBoundsInImage];
    XDFaceAnchor *anchor = [XDFaceAnchor faceAnchorWith68Points:points
                                                      imageSize:CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(viewModel:didOutputCameraPreview:)]) {
        CFRetain(sampleBuffer);
        [self.delegate viewModel:self didOutputCameraPreview:sampleBuffer];
        CFRelease(sampleBuffer);
    }
    
    if (self.faceCheckCount > 0 &&
        self.delegate &&
        [self.delegate respondsToSelector:@selector(viewModel:didOutputFaceAnchor:)]) {
        [self.delegate viewModel:self didOutputFaceAnchor:anchor];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    AVMetadataObject *obj = [metadataObjects firstObject];
    if (obj.type != AVMetadataObjectTypeFace) {
        return;
    }
    self.currentMetadataObject = obj;
    self.faceCheckCount++;
}
@end

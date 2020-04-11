//
//  XDLive2DCaptureDlibViewModel.m
//  FaceXD
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
        _cameraSession = [[CKSession alloc] initWithMultiCameraSupport:NO];
    }
    return self;
}

#pragma mark - Override Method
- (void)startCapture {
    __weak typeof(self) weakSelf = self;
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
        
        AVCaptureConnection *connection = [weakSelf.videoOutput.connections firstObject];
        if (connection) {
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            [connection setVideoMirrored:YES];
        }
        [weakSelf.faceOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    }];
    
    self.faceCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        weakSelf.faceCheckCount = 0;
    }];
    
    [super startCapture];
}

- (void)stopCapture {
    [self.cameraSession stopSessionWithCompletion:^(NSError * _Nullable error) {
        
    }];
    [self.faceCheckTimer invalidate];
    self.faceCheckTimer = nil;
    [super stopCapture];
}

#pragma mark - Delegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (self.faceCheckCount == 0) {
        return;
    }
    
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
    
    if (self.delegate &&
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

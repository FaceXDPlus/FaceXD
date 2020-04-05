//
//  XDDlibCaptureViewController.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/21.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <CameraKit/CameraKit.h>
#import <EKMetalKit/EKMetalKit.h>
#import <Masonry/Masonry.h>
#import "XDDlibCaptureViewController.h"
#import "XDDlibWarpper.h"
#import "XDFaceAnchor.h"
#import "LAppModel.h"
#import "LAppOpenGLContext.h"
#import "XDDlibModelParameterConfiguration.h"
@interface XDDlibCaptureViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) CKSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *faceOutput;
@property (nonatomic, strong) dispatch_queue_t outputQueue;
@property (nonatomic, strong) dispatch_queue_t faceQueue;

@property (nonatomic, strong) EKMetalRenderLiveview *render;
@property (nonatomic, strong) MTKView *liveview;

@property (nonatomic, strong) AVMetadataObject *currentMetadataObject;
@property (nonatomic, strong) NSTimer *faceTimer;
@property (nonatomic, assign) NSUInteger faceCount;

@property (nonatomic, strong) XDDlibShapePredictor *predictor;

@property (nonatomic, strong) LAppModel *haru;
@property (nonatomic, assign) CGSize screenSize;

@property (nonatomic, strong) XDDlibModelParameterConfiguration *parameter;
@end

@implementation XDDlibCaptureViewController

- (GLKView *)glView {
    return (GLKView *)self.view;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.predictor = [XDDlibWarpper getShapePredictor];
    [self.predictor loadModelWithPath:[[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"]];
    self.outputQueue = dispatch_queue_create("VideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    self.faceQueue = dispatch_queue_create("FaceOutputQueue", DISPATCH_QUEUE_SERIAL);
    
    __weak typeof(self) weakSelf = self;
    self.session= [[CKSession alloc] initWithMultiCameraSupport:NO];
    [self.session startSessionWithConfigBlock:^(CKSession * _Nonnull session, CKSessionConfiguration * _Nonnull config) {
        config.videoDevice = @[@(CKCaptureDeviceTypeBuiltInWideAngleCamera | CKCaptureDevicePositionFront)];
        config.sessionPresent = AVCaptureSessionPreset1280x720;
        
        weakSelf.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [weakSelf.videoOutput setVideoSettings:@{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
        }];
        [weakSelf.videoOutput setSampleBufferDelegate:weakSelf queue:weakSelf.outputQueue];
        [config addOutput:weakSelf.videoOutput forDevice:@(CKCaptureDeviceTypeBuiltInWideAngleCamera | CKCaptureDevicePositionFront)];
        
        weakSelf.faceOutput = [[AVCaptureMetadataOutput alloc] init];
        [weakSelf.faceOutput setMetadataObjectsDelegate:weakSelf queue:weakSelf.faceQueue];
        [config addOutput:weakSelf.faceOutput forDevice:@(CKCaptureDeviceTypeBuiltInWideAngleCamera | CKCaptureDevicePositionFront)];
    } completion:^(NSError * _Nullable error) {
        weakSelf.videoOutput.connections[0].videoOrientation = AVCaptureVideoOrientationPortrait;
        [weakSelf.videoOutput.connections[0] setVideoMirrored:YES];
        [weakSelf.faceOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    }];
    
    self.faceTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        weakSelf.faceCount = 0;
    }];
    
    self.screenSize = [[UIScreen mainScreen] bounds].size;
    self.preferredFramesPerSecond = 60;
    [self.glView setContext:LAppGLContext];
    LAppGLContextAction(^{
        self.haru = [[LAppModel alloc] initWithName:@"Hiyori"];
        [self.haru loadAsset];
        [self.haru startBreath];
    });
    
    self.parameter = [[XDDlibModelParameterConfiguration alloc] initWithModel:self.haru];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [LAppOpenGLContextInstance updateTime];
    glClear(GL_COLOR_BUFFER_BIT);
    [self.haru setMVPMatrixWithSize:self.screenSize];
    [self.haru onUpdateWithParameterUpdate:^{
        [self.parameter commit];
    }];
    glClearColor(0, 0, 0, 0);
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (self.faceCount == 0) {
        return;
    }
    CGRect videoInsetRect = self.render.videoInsetRect;
    CGRect faceBounds = self.currentMetadataObject.bounds;
    CGRect faceBoundsInImage = [output transformedMetadataObjectForMetadataObject:self.currentMetadataObject connection:connection].bounds;
    
    CGFloat tmp = faceBounds.origin.x;
    faceBounds.origin.x = faceBounds.origin.y;
    faceBounds.origin.y = tmp;
    
    tmp = faceBounds.size.height;
    faceBounds.size.height = faceBounds.size.width;
    faceBounds.size.width = tmp;
    
    faceBounds.origin.x = videoInsetRect.origin.x + faceBounds.origin.x * videoInsetRect.size.width;
    faceBounds.origin.y = videoInsetRect.origin.y + faceBounds.origin.y * videoInsetRect.size.height;
    faceBounds.size.width *= videoInsetRect.size.width;
    faceBounds.size.height *= videoInsetRect.size.height;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    NSArray<NSValue *> *points = [self.predictor predictorWithCVPixelBuffer:pixelBuffer rect:faceBoundsInImage];
    XDFaceAnchor *anchor = [self.predictor faceAnchorWithPoints:points imageSize:CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    [self.parameter updateParameterWithFaceAnchor:anchor];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    AVMetadataObject *obj = [metadataObjects firstObject];
    if (obj.type != AVMetadataObjectTypeFace) {
        return;
    }
    self.currentMetadataObject = obj;
    self.faceCount ++;
}

@end

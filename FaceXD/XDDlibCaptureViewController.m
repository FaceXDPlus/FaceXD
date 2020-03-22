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

@interface XDDlibCaptureViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) CKSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *faceOutput;
@property (nonatomic, strong) dispatch_queue_t outputQueue;
@property (nonatomic, strong) dispatch_queue_t faceQueue;

@property (nonatomic, strong) EKMetalRenderLiveview *render;
@property (nonatomic, strong) MTKView *liveview;

@property (nonatomic, strong) AVMetadataObject *currentMetadataObject;

@property (nonatomic, strong) UIView *faceRect;
@property (nonatomic, strong) XDDlibShapePredictor *predictor;
@property (nonatomic, strong) CAShapeLayer *pointLayer;
@end

@implementation XDDlibCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.predictor = [XDDlibWarpper getShapePredictor];
    [self.predictor loadModelWithPath:[[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"]];
    self.outputQueue = dispatch_queue_create("VideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    self.faceQueue = dispatch_queue_create("FaceOutputQueue", DISPATCH_QUEUE_SERIAL);
    
    EKMetalContext *context = [EKMetalContext defaultContext];
    self.liveview = [[MTKView alloc] initWithFrame:CGRectZero device:context.device];
    self.render = [[EKMetalRenderLiveview alloc] initWithContext:context metalView:self.liveview];
    [self.render setupRenderWithError:nil];
    [self.view addSubview:self.liveview];
    [self.liveview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    __weak typeof(self) weakSelf = self;
    self.session= [[CKSession alloc] initWithMultiCameraSupport:NO];
    [self.session startSessionWithConfigBlock:^(CKSession * _Nonnull session, CKSessionConfiguration * _Nonnull config) {
        config.videoDevice = @[@(CKCaptureDeviceTypeBuiltInWideAngleCamera | CKCaptureDevicePositionFront)];
        config.sessionPresent = AVCaptureSessionPreset640x480;
        
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
    
    self.faceRect = [[UIView alloc] init];
    self.faceRect.backgroundColor = [UIColor clearColor];
    self.faceRect.layer.borderWidth = 2;
    self.faceRect.layer.borderColor = [UIColor greenColor].CGColor;
    [self.view addSubview:self.faceRect];
}

- (void)viewDidAppear:(BOOL)animated {
    self.pointLayer = [[CAShapeLayer alloc] init];
    self.pointLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.pointLayer];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
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
    
    NSValue *rect = [NSValue valueWithCGRect:faceBounds];
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.predictor predictorWithCVPixelBuffer:pixelBuffer rect:faceBoundsInImage];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.faceRect.frame = [rect CGRectValue];
    });
    
    CFRetain(sampleBuffer);
    EKSampleBuffer *buffer = [[EKSampleBuffer alloc] initWithSampleBuffer:sampleBuffer freeWhenDone:YES];
    [self.render renderSampleBuffer:buffer];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    AVMetadataObject *obj = [metadataObjects firstObject];
    if (obj.type != AVMetadataObjectTypeFace) {
        return;
    }
    self.currentMetadataObject = obj;
}

@end

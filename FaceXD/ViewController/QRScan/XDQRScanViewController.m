//
//  XDQRScanViewController.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/17.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Masonry/Masonry.h>
#import <CameraKit/CameraKit.h>
#import "XDQRScanViewController.h"

@interface XDQRScanPreviewView : UIView
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation XDQRScanPreviewView
- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}
+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}
@end

@interface XDQRScanViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) XDQRScanPreviewView *previewView;
@property (nonatomic, strong) CKSession *session;
@property (nonatomic, strong) AVCaptureMetadataOutput *qrOutput;
@property (nonatomic, strong) dispatch_queue_t qrOutputQueue;
@end

@implementation XDQRScanViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [[CKSession alloc] initWithMultiCameraSupport:NO];
        _qrOutputQueue = dispatch_queue_create("QROutputQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.previewView = [[XDQRScanPreviewView alloc] init];
    [self.view addSubview:self.previewView];
    [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    __weak typeof(self) weakSelf = self;
    self.session = [[CKSession alloc] initWithMultiCameraSupport:NO];
    [self.session startSessionWithConfigBlock:^(CKSession * _Nonnull session, CKSessionConfiguration * _Nonnull config) {
        NSNumber *deviceID = @(CKCaptureDeviceTypeBuiltInWideAngleCamera | CKCaptureDevicePositionBack);
        config.videoDevice = @[deviceID];
        config.sessionPresent = AVCaptureSessionPreset1280x720;
        
        weakSelf.qrOutput = [[AVCaptureMetadataOutput alloc] init];
        [weakSelf.qrOutput setMetadataObjectsDelegate:weakSelf queue:weakSelf.qrOutputQueue];
        [config addOutput:weakSelf.qrOutput forDevice:deviceID];
    } completion:^(NSError * _Nullable error) {
        if (error != nil) {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        
        AVCaptureConnection *connection = [weakSelf.qrOutput.connections firstObject];
        if (connection) {
            [weakSelf.qrOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
        }
        [weakSelf.previewView.previewLayer setSession:weakSelf.session.captureSession];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.session stopSessionWithCompletion:^(NSError * _Nullable error) {
        
    }];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    AVMetadataObject *obj = [metadataObjects firstObject];
    if (obj) {
        AVMetadataMachineReadableCodeObject *qrCodeObj = (AVMetadataMachineReadableCodeObject *)obj;
        NSString *qrCode = qrCodeObj.stringValue;
        if (qrCode) {
            NSLog(@"qrCode: %@", qrCode);
            if (self.resultBlock) {
                self.resultBlock(qrCode);
            }
        }
    }
}

@end

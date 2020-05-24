//
//  XDQRScanViewController.m
//  AMGFace
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
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UILabel *exitTipsLabel;

@property (nonatomic, strong) XDQRScanPreviewView *previewView;
@property (nonatomic, strong) CKSession *session;
@property (nonatomic, strong) AVCaptureMetadataOutput *qrOutput;
@property (nonatomic, strong) dispatch_queue_t qrOutputQueue;

@property (nonatomic, assign) BOOL hasScaned;
@end

@implementation XDQRScanViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [[CKSession alloc] initWithMultiCameraSupport:NO];
        _qrOutputQueue = dispatch_queue_create("QROutputQueue", DISPATCH_QUEUE_SERIAL);
        _hasScaned = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.previewView = [[XDQRScanPreviewView alloc] init];
    [self.view addSubview:self.previewView];
    [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.text = NSLocalizedString(@"xd_qr_scan_tips", nil);
    self.tipsLabel.textColor = [UIColor whiteColor];
    self.tipsLabel.font = [UIFont systemFontOfSize:18];
    [self.view addSubview:self.tipsLabel];
    
    self.exitTipsLabel = [[UILabel alloc] init];
    self.exitTipsLabel.text = NSLocalizedString(@"xd_qr_scan_exit_tips", nil);
    self.exitTipsLabel.textColor = [UIColor whiteColor];
    self.exitTipsLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.exitTipsLabel];
    
    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.topMargin.equalTo(self.view).offset(30);
    }];
    
    [self.exitTipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(12);
    }];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewSwipeDownGesture:)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipe];
}

- (void)viewDidAppear:(BOOL)animated {
    __weak typeof(self) weakSelf = self;
    self.session = [[CKSession alloc] initWithMultiCameraSupport:NO];
    self.previewView.previewLayer.session = self.session.captureSession;
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
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.session stopSessionWithCompletion:^(NSError * _Nullable error) {
        
    }];

    NSArray *gestureRecognizerArray = [NSArray arrayWithArray:self.view.gestureRecognizers];
    for (UIGestureRecognizer *nowGestureRecognizer in gestureRecognizerArray) {
        [self.view removeGestureRecognizer:nowGestureRecognizer];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    AVMetadataObject *obj = [metadataObjects firstObject];
    if (obj) {
        AVMetadataMachineReadableCodeObject *qrCodeObj = (AVMetadataMachineReadableCodeObject *)obj;
        NSString *qrCode = qrCodeObj.stringValue;
        if (qrCode) {
            if (!self.hasScaned) {
                self.hasScaned = YES;
                if (self.resultBlock) {
                    self.resultBlock(qrCode);
                }
            }
        }
    }
}

-(void)handleViewSwipeDownGesture:(UIGestureRecognizer *)swipe{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

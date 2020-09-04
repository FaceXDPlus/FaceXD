//
//  XDLive2DControlViewController.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <KVOController/KVOController.h>
#import "XDLive2DControlViewController.h"
#import "XDLive2DControlViewModel.h"
#import "XDLive2DCaptureViewModel.h"
#import "NSString+XDIPValiual.h"
#import "XDLive2DCaptureARKitViewModel.h"
#import "XDQRScanViewController.h"
#import <GCDAsyncSocket.h>
#import <Masonry/Masonry.h>
#import "XDUserDefineKeys.h"
@interface XDLive2DControlViewController () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) XDLive2DControlViewModel *viewModel;

@property (nonatomic, assign) BOOL needShowCamera;

@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UITextField *addressField;
@property (nonatomic, weak) IBOutlet UILabel *socketPortLabel;
@property (nonatomic, weak) IBOutlet UITextField *socketPortField;
@property (nonatomic, weak) IBOutlet UILabel *captureStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *submitStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *gestureLabel;
@property (weak, nonatomic) IBOutlet UIButton *showGestureHelpButton;
@property (weak, nonatomic) IBOutlet UIStackView *controlPannelSwitchStackView;

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UILabel *appVersionLabel;
@property (nonatomic, weak) IBOutlet UILabel *resetLabel;
@property (nonatomic, weak) IBOutlet UIButton *resetButton;
@property (nonatomic, weak) IBOutlet UILabel *relativeLabel;
@property (nonatomic, weak) IBOutlet UISwitch *relativeSwitch;
@property (nonatomic, weak) IBOutlet UILabel *advancedLabel;
@property (nonatomic, weak) IBOutlet UISwitch *advancedSwitch;
@property (nonatomic, weak) IBOutlet UILabel *showCameraLabel;
@property (nonatomic, weak) IBOutlet UISwitch *showCameraSwitch;
@property (nonatomic, weak) IBOutlet UILabel *submitLabel;
@property (nonatomic, weak) IBOutlet UISwitch *submitSwitch;
@property (nonatomic, weak) IBOutlet UILabel *captureLabel;
@property (nonatomic, weak) IBOutlet UISwitch *captureSwitch;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;

@property (nonatomic, strong) NSMutableArray<GCDAsyncSocket *> *currentReachabilitys;
@property (nonatomic, strong) dispatch_queue_t reachabilityDelegateQueue;
@property (nonatomic, strong) NSTimer *reachabilityTimeoutTimer;
@end

@implementation XDLive2DControlViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _viewModel = [[XDLive2DControlViewModel alloc] init];
        _currentReachabilitys = [[NSMutableArray alloc] init];
        _reachabilityDelegateQueue = dispatch_queue_create("ReachabilityQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)viewDidLoad {
    [self setupView];
    [self bindData];
    [self syncData];
}

- (void)viewDidAppear:(BOOL)animated {
    NSError *err = [self.viewModel startLocalServer];
    if (err) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedString(@"xd_local_websocket_server_startup_error_message", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"xd_ok", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)setupView {
    self.captureLabel.text = NSLocalizedString(@"label_Capture", nil);
    self.submitLabel.text = NSLocalizedString(@"label_Submit", nil);
    self.showCameraLabel.text = NSLocalizedString(@"label_Camera", nil);
    self.resetLabel.text = NSLocalizedString(@"label_Reset", nil);
    self.versionLabel.text = NSLocalizedString(@"label_Version", nil);
    self.advancedLabel.text = NSLocalizedString(@"label_Advanced", nil);
    self.relativeLabel.text = NSLocalizedString(@"label_Relative", nil);
    self.addressLabel.text = NSLocalizedString(@"label_PCAddress", nil);
    self.socketPortLabel.text = NSLocalizedString(@"label_SocketPort", nil);
    self.gestureLabel.text = NSLocalizedString(@"label_gesture", nil);
    [_scanButton  setTitle:NSLocalizedString(@"button_Qr_scan", nil) forState:UIControlStateNormal];
    [_resetButton setTitle:NSLocalizedString(@"button_Reset", nil) forState:UIControlStateNormal];
    [_showGestureHelpButton setTitle:NSLocalizedString(@"button_show_gesture_help", nil) forState:UIControlStateNormal];
    
    
    NSNumber *lastX = [[NSUserDefaults standardUserDefaults] valueForKey:XDUserDefineKeySwitchPannelLastPointX];
    NSNumber *lastY = [[NSUserDefaults standardUserDefaults] valueForKey:XDUserDefineKeySwitchPannelLastPointY];
    if (lastX == nil ||
        lastY == nil) {
        [self.controlPannelSwitchStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(24);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(12);
        }];
    } else {
        [self layoutControlPannelSwitchStackViewWithPoint:CGPointMake(lastX.floatValue, lastY.floatValue)];
    }
}

- (void)bindData {
    NSArray *uiListenKeys = @[
        FBKVOKeyPath(_viewModel.host),
        FBKVOKeyPath(_viewModel.port),
        FBKVOKeyPath(_viewModel.appVersion),
        FBKVOKeyPath(_viewModel.captureViewModel.advanceMode),
        FBKVOKeyPath(_viewModel.captureViewModel.isCapturing),
    ];
    __weak typeof(self) weakSelf = self;
    [self.viewModel addKVOObserver:self
                       forKeyPaths:uiListenKeys
                             block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf syncData];
        });
    }];
    
    if ([self.viewModel isKindOfClass:NSClassFromString(@"XDLive2DCaptureARKitViewModel")]) {
        [self.viewModel addKVOObserver:self
                            forKeyPath:@"_viewModel.captureViewModel.worldAlignment"
                                 block:^(id  _Nullable oldValue, id  _Nullable newValue) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf syncAlignment];
            });
        }];
    }
    
    [self.viewModel addKVOObserver:self
                        forKeyPath:FBKVOKeyPath(_viewModel.captureViewModel.isCapturing) block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf syncCaptureState];
        });
    }];
    
    [self.viewModel addKVOObserver:self
                        forKeyPath:FBKVOKeyPath(_viewModel.webSocketService.isConnected)
                             block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf syncSubmitState];
        });
    }];
    
    [self syncCaptureState];
    [self syncSubmitState];
    [self syncData];
    [self syncAlignment];
}

- (void)syncCaptureState {
    BOOL state = self.viewModel.captureViewModel.isCapturing;
    if (state) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        NSString *str = NSLocalizedString(@"capturing", nil);
        /*if (![self.viewModel.captureViewModel isKindOfClass:NSClassFromString(@"XDLive2DCaptureARKitViewModel")]) {
            str = [str stringByAppendingFormat:@"(%@)", NSLocalizedString(@"xd_low_accuracy", nil)];
        } else {
            str = [str stringByAppendingFormat:@"(%@)", NSLocalizedString(@"xd_high_accuracy", nil)];
        }*/
        self.captureStateLabel.text = str;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        self.captureStateLabel.text = NSLocalizedString(@"waiting", nil);
    }
}

- (void)syncSubmitState {
    BOOL state  = self.viewModel.webSocketService.isConnected;
    self.submitSwitch.on = state;
    if (state) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        self.submitStateLabel.text = NSLocalizedString(@"started", nil);
        self.submitSwitch.enabled = YES;
    } else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.submitStateLabel.text = NSLocalizedString(@"stopped", nil);
        NSError *lastError = self.viewModel.webSocketService.lastError;
        if(lastError){
            [self alertError:lastError.localizedDescription];
            self.submitSwitch.enabled = YES;
            self.submitSwitch.on = NO;
        }
    }
}

- (void)syncData {
    self.addressField.text = self.viewModel.host;
    self.socketPortField.text = self.viewModel.port;
    self.appVersionLabel.text = self.viewModel.appVersion;
    if ([self.viewModel.captureViewModel isKindOfClass:NSClassFromString(@"XDLive2DCaptureARKitViewModel")]) {
        self.advancedSwitch.enabled = YES;
        self.advancedSwitch.on = self.viewModel.captureViewModel.advanceMode;
    } else {
        self.advancedSwitch.enabled = NO;
        self.advancedSwitch.on = NO;
    }
    self.captureSwitch.on = self.viewModel.captureViewModel.isCapturing;
    
}

- (void)syncAlignment {
    if (![self.viewModel.captureViewModel isKindOfClass:NSClassFromString(@"XDLive2DCaptureARKitViewModel")]) {
        self.relativeSwitch.on = NO;
        self.relativeSwitch.enabled = NO;
        return;
    }
    NSNumber *alignment = [self.viewModel.captureViewModel valueForKey:@"worldAlignment"];
    if (alignment) {
        BOOL isReltive = (alignment.intValue == ARWorldAlignmentCamera);
        self.relativeSwitch.on = isReltive;
        self.relativeSwitch.enabled = YES;
    } else {
        self.relativeSwitch.on = NO;
        self.relativeSwitch.enabled = NO;
    }
}

- (void)attachCaptureViewModel:(XDLive2DCaptureViewModel *)captureViewModel {
    [self.viewModel attachLive2DCaptureViewModel:captureViewModel];
    [self syncData];
    [self syncAlignment];
}

- (void)alertError:(NSString*)data {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"xd_error", nil)
                                                                       message:data
                                                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"xd_ok", nil) style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  //响应事件
                                                                  //NSLog(@"action = %@", action);
                                                              }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)layoutControlPannelSwitchStackViewWithPoint:(CGPoint)point {
    [[NSUserDefaults standardUserDefaults] setValue:@(point.x) forKey:XDUserDefineKeySwitchPannelLastPointX];
    [[NSUserDefaults standardUserDefaults] setValue:@(point.y) forKey:XDUserDefineKeySwitchPannelLastPointY];
    CGPoint centerPoint = self.view.center;
    CGFloat centerXOffset = point.x - centerPoint.x;
    CGFloat centerYOffset = point.y - centerPoint.y;
    [self.controlPannelSwitchStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX).offset(centerXOffset);
        make.centerY.equalTo(self.view.mas_centerY).offset(centerYOffset);
    }];
}

#pragma mark - Handler

- (void)handleQRCodeInput:(NSString *)qrInput {
    NSError *err = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[qrInput dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&err];
    if (err) {
        return;
    }
    
    do {
        __weak typeof(self) weakSelf = self;
        [self.reachabilityTimeoutTimer invalidate];
        self.reachabilityTimeoutTimer = nil;
        
        NSString *portString = [json objectForKey:@"port"];
        if (!(portString &&
            [portString isKindOfClass:[NSString class]])) {
            break;
        }
        
        NSDictionary *ipDict = [json objectForKey:@"IP_Dict"];
        if (ipDict &&
            [ipDict isKindOfClass:[NSDictionary class]]) {
            NSArray<NSString *> *allAddress = [ipDict allValues];
            [self.currentReachabilitys removeAllObjects];
            for (NSString *address in allAddress) {
                GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.reachabilityDelegateQueue];
                NSError *err = nil;
                [socket connectToHost:address onPort:portString.intValue error:&err];
                NSLog(@"[REACHABILITY]: connect err: %@", err);
                [self.currentReachabilitys addObject:socket];
            }
        } else {
            break;
        }
        
        self.reachabilityTimeoutTimer  = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
            NSArray *a = weakSelf.currentReachabilitys.copy;
            for (GCDAsyncSocket *obj in a) {
                [obj disconnect];
            }
            [weakSelf.currentReachabilitys removeAllObjects];
        }];
        
    } while (0);
}
- (IBAction)handleShowGestureHelpButtonDown:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"alert_gesture_help_title", nil)
                                                                   message:NSLocalizedString(@"alert_gesture_help_content", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"alert_gesture_ok", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)handleCaptureSwitchChange:(id)sender {
    if ([ARFaceTrackingConfiguration isSupported]) {
        if (self.captureSwitch.on) {
            [self.viewModel startCapture];
        } else {
            [self.viewModel stopCapture];
        }
    }
}

- (IBAction)handleSubmitSwitchChange:(id)sender {
    if (self.submitSwitch.on) {
        NSString *connectErrorStr = nil;
        
        if (!([self.addressField.text isIPString] &&
            0 < [self.socketPortField.text intValue] &&
            25565 > [self.socketPortField.text intValue])) {
            connectErrorStr = NSLocalizedString(@"illegalAddress", nil);
            [self alertError:connectErrorStr];
            self.submitSwitch.on = NO;
            self.submitSwitch.enabled = YES;
            return;
        }
        
        self.viewModel.host = self.addressField.text;
        self.viewModel.port = self.socketPortField.text;

        self.submitSwitch.enabled = NO;
        [self.viewModel connect];
    } else {
        [self.viewModel disconnect];
    }
}

- (IBAction)handleShowCameraSwitchChange:(id)sender {
    self.needShowCamera = self.showCameraSwitch.on;
}

- (IBAction)handleAdvancedSwitchChange:(id)sender {
    self.viewModel.captureViewModel.advanceMode = self.advancedSwitch.on;
}

- (IBAction)handleRelativeSwitchChange:(id)sender {
    if (self.relativeSwitch.on) {
        [self.viewModel.captureViewModel setValue:@(ARWorldAlignmentCamera) forKey:@"worldAlignment"];
    } else {
        [self.viewModel.captureViewModel setValue:@(ARWorldAlignmentGravity) forKey:@"worldAlignment"];
    }
}

- (IBAction)handleResetButtonDown:(id)sender {
    [self.viewModel disconnect];
    [self.viewModel stopCapture];
}

- (IBAction)handleAddressFieldEnd:(id)sender {
    self.viewModel.host = self.addressField.text;
    [sender resignFirstResponder];
}

- (IBAction)handlePortFieldEnd:(id)sender {
    self.viewModel.port = self.socketPortField.text;
    [sender resignFirstResponder];
}

- (IBAction)handleScanQRCodeButtonDown:(id)sender {
    [self.viewModel stopCapture];
    XDQRScanViewController *qrScan = [[XDQRScanViewController alloc] init];
    [self presentViewController:qrScan animated:YES completion:nil];
    __weak typeof(qrScan) weakQRScan = qrScan;
    __weak typeof(self) weakSelf = self;
    qrScan.resultBlock = ^(NSString * _Nonnull stringValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleQRCodeInput:stringValue];
            [weakQRScan dismissViewControllerAnimated:YES completion:nil];
        });
    };
}

#pragma mark - Delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.reachabilityTimeoutTimer invalidate];
        self.reachabilityTimeoutTimer = nil;
        
        self.viewModel.host = host;
        self.viewModel.port = [@(port) stringValue];
       
        NSArray *a = self.currentReachabilitys.copy;
        for (GCDAsyncSocket *obj in a) {
            [obj disconnect];
        }
        [self.currentReachabilitys removeAllObjects];
    });
}

@end

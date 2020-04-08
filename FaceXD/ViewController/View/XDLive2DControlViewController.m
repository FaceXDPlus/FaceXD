//
//  XDLive2DControlViewController.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <KVOController/KVOController.h>
#import "XDLive2DControlViewController.h"
#import "XDLive2DControlViewModel.h"
#import "XDLive2DCaptureViewModel.h"
#import "NSString+XDIPValiual.h"

@interface XDLive2DControlViewController ()
@property (nonatomic, strong) XDLive2DControlViewModel *viewModel;

@property (nonatomic, assign) BOOL needShowCamera;

@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UITextField *addressField;
@property (nonatomic, weak) IBOutlet UILabel *socketPortLabel;
@property (nonatomic, weak) IBOutlet UITextField *socketPortField;
@property (nonatomic, weak) IBOutlet UILabel *captureStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *submitStateLabel;

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

@property (weak, nonatomic) IBOutlet UILabel *label_Capture;
@property (weak, nonatomic) IBOutlet UILabel *label_Submit;
@property (weak, nonatomic) IBOutlet UILabel *label_30FPS;
@property (weak, nonatomic) IBOutlet UILabel *label_Camera;
@property (weak, nonatomic) IBOutlet UILabel *label_Reset;
@property (weak, nonatomic) IBOutlet UILabel *label_Version;
@property (weak, nonatomic) IBOutlet UILabel *label_Advanced;
@property (weak, nonatomic) IBOutlet UILabel *label_Relative;
@property (weak, nonatomic) IBOutlet UILabel *label_PCAddress;
@property (weak, nonatomic) IBOutlet UILabel *label_SocketPort;
@property (weak, nonatomic) IBOutlet UILabel *timeStampLabel;

@end

@implementation XDLive2DControlViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _viewModel = [[XDLive2DControlViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [self setupView];
    [self bindData];
    [self syncData];
}

- (void)setupView {
    self.label_Capture.text    = NSLocalizedString(@"label_Capture", nil);
    self.label_Submit.text     = NSLocalizedString(@"label_Submit", nil);
    self.label_30FPS.text      = NSLocalizedString(@"label_30FPS", nil);
    self.label_Camera.text     = NSLocalizedString(@"label_Camera", nil);
    self.label_Reset.text      = NSLocalizedString(@"label_Reset", nil);
    self.label_Version.text    = NSLocalizedString(@"label_Version", nil);
    self.label_Advanced.text   = NSLocalizedString(@"label_Advanced", nil);
    self.label_Relative.text   = NSLocalizedString(@"label_Relative", nil);
    self.label_PCAddress.text  = NSLocalizedString(@"label_PCAddress", nil);
    self.label_SocketPort.text = NSLocalizedString(@"label_SocketPort", nil);
    self.timeStampLabel.text   = NSLocalizedString(@"timeStamp", nil);
}

- (void)bindData {
    NSArray *uiListenKeys = @[
        FBKVOKeyPath(_viewModel.host),
        FBKVOKeyPath(_viewModel.port),
        FBKVOKeyPath(_viewModel.appVersion),
        FBKVOKeyPath(_viewModel.captureViewModel.advanceMode),
        @"captureViewModel.worldAlignment",
        FBKVOKeyPath(_viewModel.jsonSocketService.isConnected),
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
    
    [self.viewModel addKVOObserver:self
                        forKeyPath:FBKVOKeyPath(_viewModel.captureViewModel.isCapturing) block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf syncCaptureState];
        });
    }];
    
    [self.viewModel addKVOObserver:self
                        forKeyPath:FBKVOKeyPath(_viewModel.jsonSocketService.isConnected)
                             block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf syncSubmitState];
        });
    }];
    
    [self syncCaptureState];
    [self syncSubmitState];
    [self syncData];
}

- (void)syncCaptureState {
    BOOL state = self.viewModel.captureViewModel.isCapturing;
    if (state) {
        self.captureStateLabel.text = NSLocalizedString(@"capturing", nil);
    } else {
        self.captureStateLabel.text = NSLocalizedString(@"waiting", nil);
    }
}

- (void)syncSubmitState {
    BOOL state  = self.viewModel.jsonSocketService.isConnected;
    if (state) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        self.submitStateLabel.text = NSLocalizedString(@"started", nil);
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.submitStateLabel.text = NSLocalizedString(@"stopped", nil);
        NSError *lastError = self.viewModel.jsonSocketService.lastError;
        if(lastError){
            [self alertError:lastError.localizedDescription];
            NSError *err = nil;
            self.viewModel.jsonSocketService.lastError = err;
            self.submitSwitch.enabled = YES;
            self.submitSwitch.on = NO;
        }
    }
}

- (void)syncData {
    self.addressField.text = self.viewModel.host;
    self.socketPortField.text = self.viewModel.port;
    self.appVersionLabel.text = self.viewModel.appVersion;
    self.advancedSwitch.on = self.viewModel.captureViewModel.advanceMode;
    //self.submitSwitch.on = self.viewModel.jsonSocketService.isConnected;
    self.captureSwitch.on = self.viewModel.captureViewModel.isCapturing;
    
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

#pragma mark - Handler

- (IBAction)handleCaptureSwitchChange:(id)sender {
    if (self.captureSwitch.on) {
        [self.viewModel startCapture];
    } else {
        [self.viewModel stopCapture];
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
@end

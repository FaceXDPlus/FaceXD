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
#import "XDLive2DCaptureARKitViewModel.h"


@interface XDLive2DControlViewController ()
@property (nonatomic, strong) XDLive2DControlViewModel *viewModel;

@property (nonatomic, assign) BOOL needShowCamera;

@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UITextField *addressField;
@property (nonatomic, weak) IBOutlet UILabel *socketPortLabel;
@property (nonatomic, weak) IBOutlet UITextField *socketPortField;
@property (nonatomic, weak) IBOutlet UILabel *captureStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *submitStateLabel;

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
    self.captureLabel.text = NSLocalizedString(@"label_Capture", nil);
    self.submitLabel.text = NSLocalizedString(@"label_Submit", nil);
    self.showCameraLabel.text = NSLocalizedString(@"label_Camera", nil);
    self.resetLabel.text = NSLocalizedString(@"label_Reset", nil);
    self.versionLabel.text = NSLocalizedString(@"label_Version", nil);
    self.advancedLabel.text = NSLocalizedString(@"label_Advanced", nil);
    self.relativeLabel.text = NSLocalizedString(@"label_Relative", nil);
    self.addressLabel.text = NSLocalizedString(@"label_PCAddress", nil);
    self.socketPortLabel.text = NSLocalizedString(@"label_SocketPort", nil);
    self.timestampLabel.text = NSLocalizedString(@"timeStamp", nil);
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
                        forKeyPath:FBKVOKeyPath(_viewModel.jsonSocketService.isConnected)
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
        NSString *str = NSLocalizedString(@"capturing", nil);
        if (![self.viewModel.captureViewModel isKindOfClass:NSClassFromString(@"XDLive2DCaptureARKitViewModel")]) {
            str = [str stringByAppendingFormat:@"(%@)", NSLocalizedString(@"xd_low_accuracy", nil)];
        } else {
            str = [str stringByAppendingFormat:@"(%@)", NSLocalizedString(@"xd_high_accuracy", nil)];
        }
        self.captureStateLabel.text = str;
    } else {
        self.captureStateLabel.text = NSLocalizedString(@"waiting", nil);
    }
}

- (void)syncSubmitState {
    BOOL state  = self.viewModel.jsonSocketService.isConnected;
    self.submitSwitch.on = state;
    if (state) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        self.submitStateLabel.text = NSLocalizedString(@"started", nil);
        self.submitSwitch.enabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.submitStateLabel.text = NSLocalizedString(@"stopped", nil);
        NSError *lastError = self.viewModel.jsonSocketService.lastError;
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
    self.advancedSwitch.on = self.viewModel.captureViewModel.advanceMode;
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
@end

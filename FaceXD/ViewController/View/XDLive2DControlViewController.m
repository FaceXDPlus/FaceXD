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
@interface XDLive2DControlViewController ()
@property (nonatomic, strong) XDLive2DControlViewModel *viewModel;

@property (nonatomic, assign) BOOL needShowCamera;

@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UITextField *addressField;
@property (nonatomic, weak) IBOutlet UILabel *socketPortLabel;
@property (nonatomic, weak) IBOutlet UITextField *socketPortField;
@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
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
@property (nonatomic, weak) IBOutlet UILabel *showJSONLabel;
@property (nonatomic, weak) IBOutlet UISwitch *showJSONSwitch;
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
    
}

- (void)bindData {
    NSArray *uiListenKeys = @[
        FBKVOKeyPath(_viewModel.host),
        FBKVOKeyPath(_viewModel.port),
        FBKVOKeyPath(_viewModel.appVersion),
        FBKVOKeyPath(_viewModel.captureViewModel.advanceMode),
        @"captureViewModel.worldAlignment",
        FBKVOKeyPath(_viewModel.showJSON),
        FBKVOKeyPath(_viewModel.isSubmiting),
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
    [self syncData];
}

- (void)syncData {
    self.addressField.text = self.viewModel.host;
    self.socketPortField.text = self.viewModel.port;
    self.appVersionLabel.text = self.viewModel.appVersion;
    self.advancedSwitch.on = self.viewModel.captureViewModel.advanceMode;
    self.showJSONSwitch.on = self.viewModel.showJSON;
    self.submitSwitch.on = self.viewModel.isSubmiting;
    self.captureSwitch.on = self.viewModel.captureViewModel.isCapturing;
    
    NSNumber *alignment = [self.viewModel.captureViewModel valueForKey:@"worldAlignment"];
    if (alignment) {
        BOOL isReltive = (alignment.intValue == ARWorldAlignmentCamera);
        self.relativeSwitch.on = isReltive;
        self.relativeSwitch.userInteractionEnabled= YES;
    } else {
        self.relativeSwitch.on = NO;
        self.relativeSwitch.userInteractionEnabled = NO;
    }
}

- (void)attachCaptureViewModel:(XDLive2DCaptureViewModel *)captureViewModel {
    [self.viewModel attachLive2DCaptureViewModel:captureViewModel];
    [self syncData];
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
        [self.viewModel startSubmit];
    } else {
        [self.viewModel stopSubmit];
    }
}

- (IBAction)handleShowJSONSwitchChange:(id)sender {
    
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
    
}
@end

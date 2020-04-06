#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <Vision/Vision.h>
#import <QuartzCore/CABase.h>
#import <EKMetalKit/EKMetalKit.h>
#import <KVOController/KVOController.h>
#import <Masonry/Masonry.h>

#import "ViewController.h"
#import "NSString+XDIPValiual.h"
#import "UIStoryboard+XDStoryboard.h"
#import "XDLive2DControlViewController.h"
#import "XDLive2DCaptureViewController.h"
@interface ViewController ()

@property (nonatomic, strong) XDLive2DControlViewController *controlViewController;
@property (nonatomic, strong) XDLive2DCaptureViewController *captureViewController;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    self.captureViewController = [[XDLive2DCaptureViewController alloc] initWithModelName:@"Hiyori"];
    [self.view addSubview:self.captureViewController.view];
    [self addChildViewController:self.captureViewController];
    [self.captureViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.controlViewController = (XDLive2DControlViewController *)[UIStoryboard xd_viewControllerWithClass:[XDLive2DControlViewController class]];
    [self.view addSubview:self.controlViewController.view];
    [self addChildViewController:self.controlViewController];
    [self.controlViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.controlViewController attachCaptureViewModel:self.captureViewController.viewModel];
    
    [self bindData];
}

- (void)bindData {
    __weak typeof(self) weakSelf = self;
    [self.controlViewController addKVOObserver:self forKeyPath:FBKVOKeyPath(_controlViewController.needShowCamera) block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.captureViewController.liveview.hidden = ![newValue boolValue];
        });
    }];
    self.captureViewController.liveview.hidden = !self.controlViewController.needShowCamera;
    
    [self.captureViewController addKVOObserver:self
                                    forKeyPath:FBKVOKeyPath(_captureViewController.timestampString)
                                         block:^(id  _Nullable oldValue, id  _Nullable newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.controlViewController.timestampLabel.text = newValue;
        });
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    /*if (self.expressionCount == 0) return;
    static NSInteger index = 0;
    index += 1;
    if (index == self.expressionCount) {
        index = 0;
    }
    [self.hiyori startExpressionWithName:self.hiyori.expressionName[index]];*/
}

#pragma mark - Action

//- (IBAction)handleResetButton:(id)sender {
//    self.captureSwitch.on = 0;
//    self.labelJson.text = NSLocalizedString(@"jsonData", nil);
//    [self.parameterConfiguration reset];
//    self.faceCaptureStatusLabel.text = NSLocalizedString(@"waiting", nil);
//    self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
//    self.submitSwitch.on = 0;
//    self.useSocketSwitch.enabled = 1;
//    if (self.socket.isConnected){
//        [self.socket disconnect];
//        self.socket = nil;
//    }
//    self.timeStampLabel.text = NSLocalizedString(@"timeStamp", nil);
//}


//- (IBAction)handleSubmitSwitch:(id)sender {
//    if(self.submitSwitch.on == 0){
//        if (self.socket.isConnected){
//            [self.socket disconnect];
//            self.socket = nil;
//        }
//        self.submitStatusLabel.text =
//        self.useSocketSwitch.enabled = 1;
//        socketTag = 0;
//        [UIApplication sharedApplication].idleTimerDisabled = NO;
//        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//    }else{
//        if(self.useSocketSwitch.on == 1){
//            self.submitSwitch.enabled = 0;
//            if (self.socket == nil){
//                self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
//            }
//            if (self.socket.isConnected){
//                [self.socket disconnect];
//                self.socket = nil;
//            }
//            NSError *error;
//            if([self.submitCaptureAddress.text isIPString]
//               && 0 < [self.submitSocketPort.text intValue]
//               && [self.submitSocketPort.text intValue] < 25565
//            ){
//                [self.socket connectToHost:self.submitCaptureAddress.text onPort:[self.submitSocketPort.text intValue] withTimeout:5 error:&error];
//                if (error) {
//                    [self alertError:error.localizedDescription];
//                    self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
//                    self.submitSwitch.on = 0;
//                    self.submitSwitch.enabled = 1;
//                    socketTag = 0;
//                    [UIApplication sharedApplication].idleTimerDisabled = NO;
//                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//                }
//            }else{
//                [self alertError: NSLocalizedString(@"illegalAddress", nil)];
//                self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
//                self.submitSwitch.on = 0;
//                self.submitSwitch.enabled = 1;
//                socketTag = 0;
//                [UIApplication sharedApplication].idleTimerDisabled = NO;
//                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//            }
//        }else{
//            self.useSocketSwitch.enabled = 0;
//            if (self.socket.isConnected){
//                [self.socket disconnect];
//                self.socket = nil;
//            }
//            socketTag = 0;
//            self.submitStatusLabel.text = NSLocalizedString(@"started", nil);
//            [UIApplication sharedApplication].idleTimerDisabled =YES;
//            [UIApplication sharedApplication].networkActivityIndicatorVisible =YES;
//        }
//    }
//}

//- (IBAction)handleJsonSwitch:(id)sender {
//    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
//    if(self.jsonSwitch.on == 0){
//        self.labelJson.hidden = 1;
//        [accountDefaults setBool:NO forKey:@"jsonSwitch"];
//    }else{
//        self.labelJson.hidden = 0;
//        [accountDefaults setBool:YES forKey:@"jsonSwitch"];
//    }
//    [accountDefaults synchronize];
//}
//
//- (IBAction)handleAdvancedSwitch:(id)sender {
//    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
//    if(self.advancedSwitch.on == 0){
//        [accountDefaults setBool:NO forKey:@"advancedSwitch"];
//    }else{
//        [accountDefaults setBool:YES forKey:@"advancedSwitch"];
//    }
//    [accountDefaults synchronize];
//}


//- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(nonnull NSString *)host port:(uint16_t)port{
//    NSLog(NSLocalizedString(@"socketConnected", nil), host, port);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.useSocketSwitch.enabled = 0;
//        self.submitSwitch.enabled = 1;
//        self.submitStatusLabel.text = NSLocalizedString(@"started", nil);
//        [UIApplication sharedApplication].idleTimerDisabled =YES;
//        [UIApplication sharedApplication].networkActivityIndicatorVisible =YES;
//    });
//    //连接成功或者收到消息，必须开始read，否则将无法收到消息,
//    //不read的话，缓存区将会被关闭
//    // -1 表示无限时长 ,永久不失效
//    [self.socket readDataWithTimeout:-1 tag:10086];
//}

// 连接断开
//- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
//    NSLog(NSLocalizedString(@"socketDisonnected", nil), err);
//    socketTag = 0;
//    if(err != nullptr){
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self alertError:err.localizedDescription];
//            self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
//            self.submitSwitch.on = 0;
//            self.submitSwitch.enabled = 1;
//            self.useSocketSwitch.enabled = 1;
//            [UIApplication sharedApplication].idleTimerDisabled = NO;
//            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//        });
//    }
//}

//已经接收服务器返回来的数据
//- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
//    NSLog(NSLocalizedString(@"socketReceived", nil), tag, data.length);
//    //连接成功或者收到消息，必须开始read，否则将无法收到消息
//    //不read的话，缓存区将会被关闭
//    // -1 表示无限时长 ， tag
//    [self.socket readDataWithTimeout:-1 tag:10086];
//}

//消息发送成功 代理函数 向服务器 发送消息
//- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
//    NSLog(NSLocalizedString(@"socketSent", nil),tag);
//}
//
//- (IBAction)handleFpsSwitch:(id)sender {
//    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
//    if(self.fpsSwitch.on == 0){
//        [accountDefaults setBool:NO forKey:@"fpsSwitch"];
//    }else{
//        [accountDefaults setBool:YES forKey:@"fpsSwitch"];
//    }
//    [accountDefaults synchronize];
//}
//
//- (IBAction)handleSocketSwitch:(id)sender {
//    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
//    if(self.useSocketSwitch.on == 0){
//        [accountDefaults setBool:NO forKey:@"useSocketSwitch"];
//    }else{
//        [accountDefaults setBool:YES forKey:@"useSocketSwitch"];
//    }
//    [accountDefaults synchronize];
//}
//
//- (IBAction)onAddressExit:(UITextField *)sender {
//    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
//    [accountDefaults setObject:sender.text forKey: @"submitAddress"];
//    [accountDefaults synchronize];
//    [sender resignFirstResponder];
//}
//
//- (IBAction)onSocketPortExit:(UITextField *)sender {
//    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
//    [accountDefaults setObject:sender.text forKey: @"submitSocketPort"];
//    [accountDefaults synchronize];
//    [sender resignFirstResponder];
//}
//
//- (IBAction)handleAlignmentSwitchChange:(id)sender {
//    [self handleResetButton:nil];
//    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
//    [accountDefaults setObject:self.alignmentSwitch.on ? @(YES) : @(NO) forKey: @"cameraAlignment"];
//    [accountDefaults synchronize];
//    [sender resignFirstResponder];
//}

@end

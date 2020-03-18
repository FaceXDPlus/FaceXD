#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <Vision/Vision.h>

#import "XDModelParameter.h"
#import "XDDefaultModelParameterConfiguration.h"
#import "XDAdvanceModelParameterConfiguration.h"
#import "CubismModelMatrix.hpp"
#import "ViewController.h"
#import "LAppModel.h"
#import "LAppBundle.h"
#import "LAppOpenGLManager.h"

#import "GCDAsyncSocket.h"

@interface ViewController () <ARSessionDelegate,ARSCNViewDelegate,GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UILabel *labelJson;
@property (weak, nonatomic) IBOutlet UISwitch *captureSwitch;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UISwitch *startSwitch;
@property (weak, nonatomic) IBOutlet UILabel *timeStampLabel;
@property (weak, nonatomic) IBOutlet UISwitch *submitSwitch;
@property (weak, nonatomic) IBOutlet UILabel *faceCaptureStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *submitStatusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *fpsSwitch;
@property (weak, nonatomic) IBOutlet UITextField *submitCaptureAddress;
@property (weak, nonatomic) IBOutlet UITextField *submitSocketPort;
@property (weak, nonatomic) IBOutlet UISwitch *startSubmitSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *useSocketSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *jsonSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *cameraSwitch;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (weak, nonatomic) IBOutlet UISwitch *advancedSwitch;
@property (weak, nonatomic) IBOutlet ARSCNView *sceneView;
@property (weak, nonatomic) IBOutlet UISwitch *alignmentSwitch;

@property (nonatomic) GLKView *glView;
@property (nonatomic, strong) LAppModel *hiyori;
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, assign) NSInteger expressionCount;

@property (nonatomic, strong) ARSCNView *arSCNView;
@property (nonatomic, strong) ARSession *arSession;
@property (nonatomic, strong) SCNNode *faceNode;
@property (nonatomic, strong) SCNNode *leftEyeNode;
@property (nonatomic, strong) SCNNode *rightEyeNode;

@property (nonatomic, strong) XDModelParameterConfigration *parameterConfiguration;
@property (nonatomic, strong) XDModelParameterConfigration *advanceParameterConfiguration;

@property (nonatomic, strong) dispatch_queue_t networkQueue;
@property (nonatomic, strong) dispatch_queue_t processJSONQueue;
@end

@implementation ViewController

- (GLKView *)glView {
    return (GLKView *)self.view;
}

- (SCNNode *)faceNode {
    if (_faceNode == nil) {
        _faceNode = [SCNNode node];
    }
    return _faceNode;
}

- (SCNNode *)leftEyeNode {
    if (_leftEyeNode == nil) {
        _leftEyeNode = [SCNNode node];
    }
    return _leftEyeNode;
}

- (SCNNode *)rightEyeNode {
    if (_rightEyeNode == nil) {
        _rightEyeNode = [SCNNode node];
    }
    return _rightEyeNode;
}

- (XDModelParameterConfigration *)parameterConfiguration {
    if (_parameterConfiguration == nil) {
        _parameterConfiguration = [[XDDefaultModelParameterConfiguration alloc] initWithModel:self.hiyori];
    }
    return _parameterConfiguration;
}

- (XDModelParameterConfigration *)advanceParameterConfiguration {
    if (_advanceParameterConfiguration == nil) {
        _advanceParameterConfiguration = [[XDAdvanceModelParameterConfiguration alloc] initWithModel:self.hiyori];
    }
    return _advanceParameterConfiguration;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.networkQueue = dispatch_queue_create("FaceXD::NetworkQueue", DISPATCH_QUEUE_SERIAL);
    self.processJSONQueue = dispatch_queue_create("FaceXD::ProcessJSONQueue", DISPATCH_QUEUE_SERIAL);
    self.submitCaptureAddress.delegate = self;
    self.submitSocketPort.delegate = self;
    
    self.screenSize = [[UIScreen mainScreen] bounds].size;
    
    [self.glView setContext:LAppGLContext];
    LAppGLContextAction(^{
        self.hiyori = [[LAppModel alloc] initWithName:@"Hiyori"];
        [self.hiyori loadAsset];
        [self.hiyori startBreath];
    });
    
    
    [self loadConfig];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    self.screenSize = size;
}

- (void)loadConfig {
    NSString *Version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *Build   = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    self.appVersionLabel.text = [NSString stringWithFormat:@"%@ b%@", Version, Build];
    NSLog(NSLocalizedString(@"startupLog", nil) , Version, Build);
    
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    if([accountDefaults objectForKey: @"submitAddress"] == nil){
        [accountDefaults setObject:@"http://127.0.0.1:12345" forKey: @"submitAddress"];
        [accountDefaults synchronize];
    }
    if([accountDefaults objectForKey: @"submitSocketPort"] == nil){
        [accountDefaults setObject:@"8040" forKey: @"submitSocketPort"];
        [accountDefaults synchronize];
    }
    self.submitCaptureAddress.text = [accountDefaults objectForKey: @"submitAddress"];
    self.submitSocketPort.text = [accountDefaults objectForKey: @"submitSocketPort"];
    self.fpsSwitch.on = [accountDefaults boolForKey: @"fpsSwitch"];
    self.jsonSwitch.on = [accountDefaults boolForKey: @"jsonSwitch"];
    if(self.jsonSwitch.on == 1){
        self.labelJson.hidden = 0;
    }
    self.useSocketSwitch.on = [accountDefaults boolForKey: @"useSocketSwitch"];
    self.advancedSwitch.on = [accountDefaults boolForKey: @"advancedSwitch"];
    NSNumber *alignmentNumber = [accountDefaults objectForKey:@"cameraAlignment"];
    if (alignmentNumber == nil) {
        alignmentNumber = @(YES);
        [accountDefaults setObject:alignmentNumber forKey:@"cameraAlignment"];
    }
    self.alignmentSwitch.on = alignmentNumber.boolValue;
    //self.sceneView.showsStatistics = YES;
    self.sceneView.autoenablesDefaultLighting = YES;
    self.sceneView.debugOptions = SCNDebugOptionNone;
    
    SCNScene *scene = [SCNScene new];
    self.sceneView.scene = scene;
    self.sceneView.hidden = 1;
}

- (void)setupARSession {
    self.arSession = [[ARSession alloc] init];
    ARFaceTrackingConfiguration *faceTracking = [[ARFaceTrackingConfiguration alloc] init];
    faceTracking.worldAlignment = self.alignmentSwitch.on ? ARWorldAlignmentCamera : ARWorldAlignmentGravity;
    self.arSession.delegate = self;
    [self.arSession runWithConfiguration:faceTracking];
    self.sceneView.session = self.arSession;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [LAppOpenGLManagerInstance updateTime];
    
    glClear(GL_COLOR_BUFFER_BIT);

    [self.hiyori setMVPMatrixWithSize:self.screenSize];
    [self.hiyori onUpdateWithParameterUpdate:^{
        [self.parameterConfiguration commit];
    }];

    glClearColor(0, 0, 0, 1);
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

- (IBAction)handleResetButton:(id)sender {
    self.captureSwitch.on = 0;
    self.labelJson.text = NSLocalizedString(@"jsonData", nil);
    [self.parameterConfiguration reset];
    self.faceCaptureStatusLabel.text = NSLocalizedString(@"waiting", nil);
    self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
    self.submitSwitch.on = 0;
    self.useSocketSwitch.enabled = 1;
    self.timeStampLabel.text = NSLocalizedString(@"timeStamp", nil);
}

- (IBAction)handleFaceCaptureSwitch:(id)sender {
    if(self.captureSwitch.on == 0){
        self.faceCaptureStatusLabel.text = NSLocalizedString(@"waiting", nil);
    }else{
        [self setupARSession];
        self.faceCaptureStatusLabel.text = NSLocalizedString(@"capturing", nil);
    }
}

- (IBAction)handleSubmitSwitch:(id)sender {
    if(self.submitSwitch.on == 0){
        if (self.socket.isConnected){
            [self.socket disconnect];
            self.socket = nil;
        }
        self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
        self.useSocketSwitch.enabled = 1;
        socketTag = 0;
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }else{
        if(self.useSocketSwitch.on == 1){
            self.submitSwitch.enabled = 0;
            if (self.socket == nil){
                self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
            }
            if (self.socket.isConnected){
                [self.socket disconnect];
                self.socket = nil;
            }
            NSError *error;
            if([self isValidatIP:self.submitCaptureAddress.text]
               && 0 < [self.submitSocketPort.text intValue]
               && [self.submitSocketPort.text intValue] < 25565
            ){
                [self.socket connectToHost:self.submitCaptureAddress.text onPort:[self.submitSocketPort.text intValue] withTimeout:5 error:&error];
                if (error) {
                    [self alertError:error.localizedDescription];
                    self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
                    self.submitSwitch.on = 0;
                    self.submitSwitch.enabled = 1;
                    socketTag = 0;
                    [UIApplication sharedApplication].idleTimerDisabled = NO;
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            }else{
                [self alertError: NSLocalizedString(@"illegalAddress", nil)];
                self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
                self.submitSwitch.on = 0;
                self.submitSwitch.enabled = 1;
                socketTag = 0;
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }else{
            self.useSocketSwitch.enabled = 0;
            if (self.socket.isConnected){
                [self.socket disconnect];
                self.socket = nil;
            }
            socketTag = 0;
            self.submitStatusLabel.text = NSLocalizedString(@"started", nil);
            [UIApplication sharedApplication].idleTimerDisabled =YES;
            [UIApplication sharedApplication].networkActivityIndicatorVisible =YES;
        }
    }
}

- (IBAction)handleJsonSwitch:(id)sender {
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    if(self.jsonSwitch.on == 0){
        self.labelJson.hidden = 1;
        [accountDefaults setBool:NO forKey:@"jsonSwitch"];
    }else{
        self.labelJson.hidden = 0;
        [accountDefaults setBool:YES forKey:@"jsonSwitch"];
    }
    [accountDefaults synchronize];
}

- (IBAction)handleAdvancedSwitch:(id)sender {
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    if(self.advancedSwitch.on == 0){
        [accountDefaults setBool:NO forKey:@"advancedSwitch"];
    }else{
        [accountDefaults setBool:YES forKey:@"advancedSwitch"];
    }
    [accountDefaults synchronize];
}

- (IBAction)handleCameraSwitch:(id)sender {
    if(self.cameraSwitch.on == 0){
        self.sceneView.hidden = 1;
    }else{
        self.sceneView.hidden = 0;
    }
}

-(BOOL)checkSocketAddress:(NSArray*)array {
    if([array count] == 2){
        NSScanner* scan = [NSScanner scannerWithString:[array objectAtIndex:1]];
        int val;
        if([self isValidatIP:[array objectAtIndex:0]] && ([scan scanInt:&val] && [scan isAtEnd])){
            if(0 < [[array objectAtIndex:1] intValue] && [[array objectAtIndex:1] intValue] < 25565){
                return true;
            }
        }
    }
    return false;
}

-(BOOL)isValidatIP:(NSString *)ipAddress{
    
    NSString  *urlRegEx =@"^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                        "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                        "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                        "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:ipAddress];

}

- (void)alertError:(NSString*)data {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"errorTitle", nil)
                                                                       message:data
                                                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"errorOK", nil) style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  //响应事件
                                                                  //NSLog(@"action = %@", action);
                                                              }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(nonnull NSString *)host port:(uint16_t)port{
    NSLog(NSLocalizedString(@"socketConnected", nil), host, port);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.useSocketSwitch.enabled = 0;
        self.submitSwitch.enabled = 1;
        self.submitStatusLabel.text = NSLocalizedString(@"started", nil);
        [UIApplication sharedApplication].idleTimerDisabled =YES;
        [UIApplication sharedApplication].networkActivityIndicatorVisible =YES;
    });
    //连接成功或者收到消息，必须开始read，否则将无法收到消息,
    //不read的话，缓存区将会被关闭
    // -1 表示无限时长 ,永久不失效
    [self.socket readDataWithTimeout:-1 tag:10086];
}

// 连接断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(NSLocalizedString(@"socketDisonnected", nil), err);
    socketTag = 0;
    if(err != nullptr){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertError:err.localizedDescription];
            self.submitStatusLabel.text = NSLocalizedString(@"stopped", nil);
            self.submitSwitch.on = 0;
            self.submitSwitch.enabled = 1;
            self.useSocketSwitch.enabled = 1;
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    }
}

//已经接收服务器返回来的数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(NSLocalizedString(@"socketReceived", nil), tag, data.length);
    //连接成功或者收到消息，必须开始read，否则将无法收到消息
    //不read的话，缓存区将会被关闭
    // -1 表示无限时长 ， tag
    [self.socket readDataWithTimeout:-1 tag:10086];
}

//消息发送成功 代理函数 向服务器 发送消息
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(NSLocalizedString(@"socketSent", nil),tag);
}

- (IBAction)handleFpsSwitch:(id)sender {
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    if(self.fpsSwitch.on == 0){
        [accountDefaults setBool:NO forKey:@"fpsSwitch"];
    }else{
        [accountDefaults setBool:YES forKey:@"fpsSwitch"];
    }
    [accountDefaults synchronize];
}

- (IBAction)handleSocketSwitch:(id)sender {
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    if(self.useSocketSwitch.on == 0){
        [accountDefaults setBool:NO forKey:@"useSocketSwitch"];
    }else{
        [accountDefaults setBool:YES forKey:@"useSocketSwitch"];
    }
    [accountDefaults synchronize];
}

- (IBAction)onAddressExit:(UITextField *)sender {
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:sender.text forKey: @"submitAddress"];
    [accountDefaults synchronize];
    [sender resignFirstResponder];
}

- (IBAction)onSocketPortExit:(UITextField *)sender {
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:sender.text forKey: @"submitSocketPort"];
    [accountDefaults synchronize];
    [sender resignFirstResponder];
}

- (IBAction)handleAlignmentSwitchChange:(id)sender {
    [self handleResetButton:nil];
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:self.alignmentSwitch.on ? @(YES) : @(NO) forKey: @"cameraAlignment"];
    [accountDefaults synchronize];
    [sender resignFirstResponder];
}

#pragma mark - Delegate
#pragma mark - ARSCNViewDelegate
#pragma mark - ARSessionDelegate

- (ARSCNView *)arSCNView{
    if (!_arSCNView) {
        _arSCNView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
        _arSCNView.delegate = self;
        _arSCNView.session = self.arSession;
    }
    return _arSCNView;
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<__kindof ARAnchor *> *)anchors {
    if(self.captureSwitch.on == 1){
        ARFaceAnchor *faceAnchor = anchors.firstObject;
        if (faceAnchor) {
            UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;

            NSString *timeString = [NSString stringWithFormat:@"%llu", recordTime];
            NSString *lastTimeString = [NSString stringWithFormat:@"%llu", lastRecordTime];
            
            if(self.fpsSwitch.on == 1){
                if((recordTime - lastRecordTime) < timeInOneFps){
                    //self.timeStampLabel.text = @"跳过本数据";
                    return;
                }else{
                    lastRecordTime = recordTime;
                    self.timeStampLabel.text = [NSString stringWithFormat:NSLocalizedString(@"30FPSLabel", nil), lastTimeString, timeString];
                }
            }else{
                self.timeStampLabel.text = [NSString stringWithFormat:NSLocalizedString(@"60FPSLabel", nil), timeString];
            }
            
            self.faceNode.simdTransform = faceAnchor.transform;
            if (@available(iOS 12.0, *)) {
                self.leftEyeNode.simdTransform = faceAnchor.leftEyeTransform;
                self.rightEyeNode.simdTransform = faceAnchor.rightEyeTransform;
            }
            
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if ([self.parameterConfiguration isKindOfClass:[XDDefaultModelParameterConfiguration class]]) {
                [self.parameterConfiguration setValue:@(self.arSession.configuration.worldAlignment) forKey:@"worldAlignment"];
                [self.parameterConfiguration setValue:@(orientation) forKey:@"orientation"];
            }
            if ([self.advanceParameterConfiguration isKindOfClass:[XDAdvanceModelParameterConfiguration class]]) {
                [self.advanceParameterConfiguration setValue:@(self.arSession.configuration.worldAlignment) forKey:@"worldAlignment"];
                [self.advanceParameterConfiguration setValue:@(orientation) forKey:@"orientation"];
            }
            
            [self.parameterConfiguration updateParameterWithFaceAnchor:faceAnchor
                                                              faceNode:self.faceNode
                                                           leftEyeNode:self.leftEyeNode
                                                          rightEyeNode:self.rightEyeNode];
            [self.advanceParameterConfiguration updateParameterWithFaceAnchor:faceAnchor
                                                                 faceNode:self.faceNode
                                                              leftEyeNode:self.leftEyeNode
                                                             rightEyeNode:self.rightEyeNode];
            self.parameterConfiguration.parameter.timestamp = timeString;
            self.advanceParameterConfiguration.parameter.timestamp = timeString;
            
            NSDictionary *param = @{};
            if(self.advancedSwitch.on == 1){
                param = [self.advanceParameterConfiguration.parameter parameterValueDictionary];
            } else {
                param = [self.parameterConfiguration.parameter parameterValueDictionary];
            }
        
            dispatch_async(self.processJSONQueue, ^{
                NSError *parseError = nil;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:&parseError];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                if (!jsonData) {
                    NSLog(@"%@",parseError);
                }else{
                    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];

                    NSRange range = {0,jsonString.length};
                    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
                    NSRange range2 = {0,mutStr.length};
                    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
                    NSMutableString *mutStrShow = mutStr;
                    NSRange range3 = {0,mutStrShow.length};
                    [mutStrShow replaceOccurrencesOfString:@"," withString:@",\n" options:NSLiteralSearch range:range3];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.labelJson.text = mutStrShow;
                        if(self.startSubmitSwitch.on == 1){
                            if(self.useSocketSwitch.on == 0){
                                [self postJson:mutStr];
                            }else{
                                [self postSocket:mutStr];
                            }
                        }
                    });
                }
            });
        }
    }
}

- (void)postJson:(NSString*)data {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:self.submitCaptureAddress.text];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[NSString stringWithFormat:@"jsonData=%s", [data UTF8String]] dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        //NSLog(@"%@",dict);
        
    }];
    [dataTask resume];
}

- (void)postSocket:(NSString*)dataJson {
    if(self.socket.isConnected){
        NSData *data = [dataJson dataUsingEncoding:NSUTF8StringEncoding];
        //NSUInteger size = data.length;
        //NSData *lengthData = [[NSString stringWithFormat:@"[length=%ld]",size] dataUsingEncoding:NSUTF8StringEncoding];
        //NSMutableData *mData = [NSMutableData dataWithData:lengthData];
        //[mData appendData:data];
        //NSLog(@"%d", socketTag);
        socketTag += 1;
        [self.socket writeData:data withTimeout:-1 tag:socketTag];
    }
}

@end

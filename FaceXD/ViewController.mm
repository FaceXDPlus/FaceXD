#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <Vision/Vision.h>
#import "XDControlValueLinear.h"

#import "CubismModelMatrix.hpp"
#import "ViewController.h"
#import "LAppModel.h"
#import "LAppBundle.h"
#import "LAppOpenGLManager.h"

#import "GCDAsyncSocket.h"

@interface ViewController () <ARSessionDelegate,ARSCNViewDelegate,GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UILabel *LabelJson;
@property (weak, nonatomic) IBOutlet UISwitch *Switch;
@property (weak, nonatomic) IBOutlet UIButton *ResetButton;
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
@property (weak, nonatomic) IBOutlet UISwitch *JsonSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *cameraSwitch;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (weak, nonatomic) IBOutlet UISwitch *advancedSwitch;
@property (weak, nonatomic) IBOutlet ARSCNView *sceneView;

@property (nonatomic, assign) CGFloat headYaw;
@property (nonatomic, assign) CGFloat headPitch;
@property (nonatomic, assign) CGFloat headRoll;
@property (nonatomic, assign) CGFloat mouthOpenY;
@property (nonatomic, assign) CGFloat mouthForm;
@property (nonatomic, assign) CGFloat eyeLOpen;
@property (nonatomic, assign) CGFloat eyeROpen;
@property (nonatomic, assign) CGFloat eyeBrowYL;
@property (nonatomic, assign) CGFloat eyeBrowYR;
@property (nonatomic, assign) CGFloat eyeBrowAngleL;
@property (nonatomic, assign) CGFloat eyeBrowAngleR;
@property (nonatomic, assign) CGFloat eyeX;
@property (nonatomic, assign) CGFloat eyeY;
@property (nonatomic, assign) CGFloat bodyX;
@property (nonatomic, assign) CGFloat bodyY;
@property (nonatomic, assign) CGFloat bodyAngleX;
@property (nonatomic, assign) CGFloat bodyAngleY;
@property (nonatomic, assign) CGFloat bodyAngleZ;

@property (nonatomic) GLKView *glView;
@property (nonatomic, strong) LAppModel *haru;
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, assign) NSInteger expressionCount;

@property (nonatomic, strong) ARSCNView *arSCNView;
@property (nonatomic, strong) ARSession *arSession;
@property (nonatomic, strong) SCNNode *faceNode;
@property (nonatomic, strong) SCNNode *leftEyeNode;
@property (nonatomic, strong) SCNNode *rightEyeNode;

@property (nonatomic, strong) XDControlValueLinear *eyeLinearX;
@property (nonatomic, strong) XDControlValueLinear *eyeLinearY;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.submitCaptureAddress.delegate = self;
    self.submitSocketPort.delegate = self;
    
    self.screenSize = [[UIScreen mainScreen] bounds].size;
    
    [self.glView setContext:LAppGLContext];
    LAppGLContextAction(^{
        self.haru = [[LAppModel alloc] initWithName:@"Hiyori"];
        [self.haru loadAsset];
        self.expressionCount = self.haru.expressionName.count;
        self.eyeLinearX = [[XDControlValueLinear alloc] initWithOutputMax:[self.haru paramMaxValue:LAppParamEyeBallX].doubleValue
                                                               outputMin:[self.haru paramMinValue:LAppParamEyeBallX].doubleValue
                                                                inputMax:45
                                                                inputMin:-45];
        self.eyeLinearY = [[XDControlValueLinear alloc] initWithOutputMax:[self.haru paramMaxValue:LAppParamEyeBallY].doubleValue
                                                                outputMin:[self.haru paramMinValue:LAppParamEyeBallY].doubleValue
                                                                 inputMax:45
                                                                 inputMin:-45];
        [self.haru startBreath];
    });
    
    
    [self loadConfig];
    
    [self setupARSession];
}

- (void)loadConfig {
    NSString *Version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *Build   = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    self.appVersionLabel.text = [NSString stringWithFormat:@"%@ b%@", Version, Build];
    NSLog(@"APP对外展示的版本号为：%@ b%@", Version, Build);
    
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
    self.JsonSwitch.on = [accountDefaults boolForKey: @"JsonSwitch"];
    if(self.JsonSwitch.on == 1){
        self.LabelJson.hidden = 0;
    }
    self.useSocketSwitch.on = [accountDefaults boolForKey: @"useSocketSwitch"];
    self.advancedSwitch.on = [accountDefaults boolForKey: @"advancedSwitch"];
    
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
    faceTracking.worldAlignment = ARWorldAlignmentCamera;
    self.arSession.delegate = self;
    [self.arSession runWithConfiguration:faceTracking];
    self.sceneView.session = self.arSession;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [LAppOpenGLManagerInstance updateTime];
    
    glClear(GL_COLOR_BUFFER_BIT);
    [self.haru setMVPMatrixWithSize:self.screenSize];
    [self.haru onUpdateWithParameterUpdate:^{
        [self.haru setParam:LAppParamAngleX forValue:@(self.headYaw)];
        [self.haru setParam:LAppParamAngleY forValue:@(self.headPitch)];
        [self.haru setParam:LAppParamAngleZ forValue:@(self.headRoll)];
        [self.haru setParam:LAppParamMouthOpenY forValue:@(self.mouthOpenY)];
        [self.haru setParam:LAppParamMouthForm forValue:@(self.mouthForm)];
        [self.haru setParam:LAppParamEyeLOpen forValue:@(self.eyeLOpen)];
        [self.haru setParam:LAppParamEyeROpen forValue:@(self.eyeROpen)];
        [self.haru setParam:LAppParamEyeBrowLOpen forValue:@(self.eyeBrowYL)];
        [self.haru setParam:LAppParamEyeBrowROpen forValue:@(self.eyeBrowYR)];
        [self.haru setParam:LAppParamEyeBrowLAngle forValue:@(self.eyeBrowAngleL)];
        [self.haru setParam:LAppParamEyeBrowRAngle forValue:@(self.eyeBrowAngleR)];
        [self.haru setParam:LAppParamEyeBallX forValue:@(self.eyeX)];
        [self.haru setParam:LAppParamEyeBallY forValue:@(self.eyeY)];
        [self.haru setParam:LAppParamBodyAngleX forValue:@(self.bodyAngleX)];
        [self.haru setParam:LAppParamBodyAngleY forValue:@(self.bodyAngleY)];
        [self.haru setParam:LAppParamBodyAngleZ forValue:@(self.bodyAngleZ)];
    }];
    glClearColor(0, 1, 0, 1);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.expressionCount == 0) return;
    static NSInteger index = 0;
    index += 1;
    if (index == self.expressionCount) {
        index = 0;
    }
    [self.haru startExpressionWithName:self.haru.expressionName[index]];
}

#pragma mark - Action

- (IBAction)handleResetButton:(id)sender {
    self.Switch.on = 0;
    NSString *data = @"Json化提交数据";
    self.LabelJson.text = data;
    self.headPitch = 0;
    self.headYaw = 0;
    self.headRoll = 0;
    self.bodyAngleX = 0;
    self.bodyAngleY = 0;
    self.bodyAngleZ = 0;
    self.eyeLOpen = 0;
    self.eyeROpen = 0;
    self.eyeX = 0;
    self.eyeY = 0;
    self.mouthOpenY = 0;
    self.faceCaptureStatusLabel.text = @"未开始";
    self.timeStampLabel.text = @"运行时间戳";
}

- (IBAction)handleFaceCaptureSwitch:(id)sender {
    if(self.Switch.on == 0){
        self.faceCaptureStatusLabel.text = @"未开始";
    }else{
        self.faceCaptureStatusLabel.text = @"捕捉中";
    }
}

- (IBAction)handleSubmitSwitch:(id)sender {
    if(self.submitSwitch.on == 0){
        if (self.socket.isConnected){
            [self.socket disconnect];
            self.socket = nil;
        }
        self.submitStatusLabel.text = @"未提交";
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
                    self.submitStatusLabel.text = @"未提交";
                    self.submitSwitch.on = 0;
                    self.submitSwitch.enabled = 1;
                    socketTag = 0;
                    [UIApplication sharedApplication].idleTimerDisabled = NO;
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            }else{
                [self alertError:@"提交地址错误！请使用正确的格式提交！\n示范推流地址：127.0.0.1\n示范推流端口：8040"];
                self.submitStatusLabel.text = @"未提交";
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
            self.submitStatusLabel.text = @"提交中";
            [UIApplication sharedApplication].idleTimerDisabled =YES;
            [UIApplication sharedApplication].networkActivityIndicatorVisible =YES;
        }
    }
}

- (IBAction)handleJsonSwitch:(id)sender {
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    if(self.JsonSwitch.on == 0){
        self.LabelJson.hidden = 1;
        [accountDefaults setBool:NO forKey:@"JsonSwitch"];
    }else{
        self.LabelJson.hidden = 0;
        [accountDefaults setBool:YES forKey:@"JsonSwitch"];
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
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"错误"
                                                                       message:data
                                                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  //响应事件
                                                                  //NSLog(@"action = %@", action);
                                                              }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(nonnull NSString *)host port:(uint16_t)port{
    NSLog(@"连接成功 : %@---%d",host,port);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.useSocketSwitch.enabled = 0;
        self.submitSwitch.enabled = 1;
        self.submitStatusLabel.text = @"提交中";
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
    NSLog(@"断开 socket连接 原因:%@",err);
    socketTag = 0;
    if(err != nullptr){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertError:err.localizedDescription];
            self.submitStatusLabel.text = @"未提交";
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
    NSLog(@"接收到tag = %ld : %ld 长度的数据",tag,data.length);
    //连接成功或者收到消息，必须开始read，否则将无法收到消息
    //不read的话，缓存区将会被关闭
    // -1 表示无限时长 ， tag
    [self.socket readDataWithTimeout:-1 tag:10086];
}

//消息发送成功 代理函数 向服务器 发送消息
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"%ld 发送数据成功",tag);
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
    if(self.Switch.on == 1){
        ARFaceAnchor *faceAnchor = anchors.firstObject;
        if (faceAnchor) {
            UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;

            NSString*timeString = [NSString stringWithFormat:@"%llu", recordTime];
            NSString*lastTimeString = [NSString stringWithFormat:@"%llu", lastRecordTime];
            
            if(self.fpsSwitch.on == 1){
                if((recordTime - lastRecordTime) < timeInOneFps){
                    //self.timeStampLabel.text = @"跳过本数据";
                    return;
                }else{
                    lastRecordTime = recordTime;
                    self.timeStampLabel.text = [NSString stringWithFormat:@"旧%@新%@", lastTimeString, timeString];
                }
            }else{
                self.timeStampLabel.text = [NSString stringWithFormat:@"新%@", timeString];
            }
            
            self.faceNode.simdTransform = faceAnchor.transform;
            if (@available(iOS 12.0, *)) {
                self.leftEyeNode.simdTransform = faceAnchor.leftEyeTransform;
                self.rightEyeNode.simdTransform = faceAnchor.rightEyeTransform;
            }
            
            self.headPitch = -(180 / M_PI) * self.faceNode.eulerAngles.x;
            self.headYaw = (180 / M_PI) * self.faceNode.eulerAngles.y;
            self.headRoll = -(180 / M_PI) * self.faceNode.eulerAngles.z + 90.0;
            self.bodyAngleX = self.headYaw / 4;
            self.bodyAngleY = self.headPitch / 2;
            self.bodyAngleZ = self.headRoll / 2;
            
            self.eyeLOpen = 1 - faceAnchor.blendShapes[ARBlendShapeLocationEyeBlinkLeft].floatValue * 1.3;
            self.eyeROpen = 1 - faceAnchor.blendShapes[ARBlendShapeLocationEyeBlinkRight].floatValue * 1.3;
            self.eyeX = [self.eyeLinearX calc:(180 / M_PI) * self.leftEyeNode.eulerAngles.y];
            self.eyeY = - [self.eyeLinearY calc:(180 / M_PI) * self.leftEyeNode.eulerAngles.x];
            self.mouthOpenY = faceAnchor.blendShapes[ARBlendShapeLocationJawOpen].floatValue * 1.8;
            
            CGFloat innerUp = faceAnchor.blendShapes[ARBlendShapeLocationBrowInnerUp].floatValue;
            CGFloat outerUpL = faceAnchor.blendShapes[ARBlendShapeLocationBrowOuterUpLeft].floatValue;
            CGFloat outerUpR = faceAnchor.blendShapes[ARBlendShapeLocationBrowOuterUpRight].floatValue;
            CGFloat downL = faceAnchor.blendShapes[ARBlendShapeLocationBrowDownLeft].floatValue;
            CGFloat downR = faceAnchor.blendShapes[ARBlendShapeLocationBrowDownRight].floatValue;
            self.eyeBrowYL = (innerUp + outerUpL) / 2;
            self.eyeBrowYR = (innerUp + outerUpR) / 2;
            self.eyeBrowAngleL = 17*(innerUp - outerUpL) - downL - 2.5;
            self.eyeBrowAngleR = 17*(innerUp - outerUpR) - downR - 2.5;
            CGFloat mouthFunnel = faceAnchor.blendShapes[ARBlendShapeLocationMouthFunnel].floatValue;
            CGFloat mouthLeft = faceAnchor.blendShapes[ARBlendShapeLocationMouthFrownLeft].floatValue;
            CGFloat mouthRight = faceAnchor.blendShapes[ARBlendShapeLocationMouthFrownRight].floatValue;
            CGFloat mouthSmileLeft = faceAnchor.blendShapes[ARBlendShapeLocationMouthSmileLeft].floatValue;
            CGFloat mouthSmileRight = faceAnchor.blendShapes[ARBlendShapeLocationMouthSmileRight].floatValue;
            CGFloat mouthForm = 0 - (mouthLeft - mouthSmileLeft + mouthRight - mouthSmileRight) / 2 * 8 - 1 / 3;
            if(mouthForm < 0){
                mouthForm = mouthForm - mouthFunnel;
            }
            self.mouthForm = mouthForm;
            NSDictionary *param = @{
                            @"headPitch"       : [NSString stringWithFormat: @"%.5lf", self.headPitch],
                            @"headYaw"         : [NSString stringWithFormat: @"%.5lf", self.headYaw],
                            @"headRoll"        : [NSString stringWithFormat: @"%.5lf", self.headRoll],
                            @"bodyAngleX"      : [NSString stringWithFormat: @"%.5lf", self.bodyAngleX],
                            @"bodyAngleY"      : [NSString stringWithFormat: @"%.5lf", self.bodyAngleY],
                            @"bodyAngleZ"      : [NSString stringWithFormat: @"%.5lf", self.bodyAngleZ],
                            @"eyeLOpen"        : [NSString stringWithFormat: @"%.5lf", self.eyeLOpen],
                            @"eyeROpen"        : [NSString stringWithFormat: @"%.5lf", self.eyeROpen],
                            @"eyeBrowYL"       : [NSString stringWithFormat: @"%.5lf", self.eyeBrowYL],
                            @"eyeBrowYR"       : [NSString stringWithFormat: @"%.5lf", self.eyeBrowYR],
                            @"eyeBrowAngleL"   : [NSString stringWithFormat: @"%.5lf", self.eyeBrowAngleL],
                            @"eyeBrowAngleR"   : [NSString stringWithFormat: @"%.5lf", self.eyeBrowAngleR],
                            @"eyeX"            : [NSString stringWithFormat: @"%.5lf", self.eyeX],
                            @"eyeY"            : [NSString stringWithFormat: @"%.5lf", self.eyeY],
                            @"mouthOpenY"      : [NSString stringWithFormat: @"%.5lf", self.mouthOpenY],
                            @"mouthForm"       : [NSString stringWithFormat: @"%.5lf", self.mouthForm],
                            @"timeStamp"       : timeString,
            };
            if(self.advancedSwitch.on == 1){
                param = faceAnchor.blendShapes;
            }
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
                self.LabelJson.text = mutStr;
                if(self.startSubmitSwitch.on == 1){
                    if(self.useSocketSwitch.on == 0){
                        [self postJson:mutStr];
                    }else{
                        [self postSocket:mutStr];
                    }
                }
            }
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
        NSLog(@"%d", socketTag);
        socketTag += 1;
        [self.socket writeData:data withTimeout:-1 tag:socketTag];
    }
}

- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (IBAction)didClickConnectSocket:(id)sender {
    // 创建socket
    if (self.socket == nil)
        // 并发队列，这个队列将影响delegate回调,但里面是同步函数！保证数据不混乱，一条一条来
        // 这里最好是写自己并发队列
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    // 连接socket
    if (!self.socket.isConnected){
        NSError *error;
        [self.socket connectToHost:@"127.0.0.1" onPort:8040 withTimeout:-1 error:&error];
        if (error) NSLog(@"%@",error);
    }
}

- (IBAction)didClickSendAction:(id)sender {
    
    NSData *data = [@"发送的消息内容" dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:-1 tag:10086];
}

- (IBAction)didClickReconnectAction:(id)sender {
    // 创建socket
    if (self.socket == nil)
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    // 连接socket
    if (!self.socket.isConnected){
        NSError *error;
        [self.socket connectToHost:@"127.0.0.1" onPort:8040 withTimeout:-1 error:&error];
        if (error) NSLog(@"%@",error);
    }
}

- (IBAction)didClickCloseAction:(id)sender {
    [self.socket disconnect];
    self.socket = nil;
}

@end

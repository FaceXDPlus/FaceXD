#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>
#import <CoreVideo/CoreVideo.h>
#import "csmString.hpp"
#import "csmMap.hpp"
#import "CubismUserModel.hpp"
#import "CubismIdManager.hpp"
#import "CubismDefaultParameterId.hpp"
#import "CubismModelSettingJson.hpp"
#import "CubismRenderer_OpenGLES2.hpp"
#import "LAppBundle.h"
#import "LAppModel.h"
#import "LAppOpenGLContext.h"

#define LAppModelParameterID(key) Csm::CubismFramework::GetIdManager()->GetId(Csm::DefaultParameterId::key)

#define LAppParamMake(key) [NSString stringWithCString:Csm::DefaultParameterId::key encoding:NSUTF8StringEncoding];

LAppParam const LAppParamAngleX = LAppParamMake(ParamAngleX);
LAppParam const LAppParamAngleY = LAppParamMake(ParamAngleY);
LAppParam const LAppParamAngleZ = LAppParamMake(ParamAngleZ);
LAppParam const LAppParamMouthOpenY = LAppParamMake(ParamMouthOpenY);
LAppParam const LAppParamMouthForm = LAppParamMake(ParamMouthForm);
LAppParam const LAppParamEyeLOpen = LAppParamMake(ParamEyeLOpen);
LAppParam const LAppParamEyeROpen = LAppParamMake(ParamEyeROpen);
LAppParam const LAppParamEyeBallX = LAppParamMake(ParamEyeBallX);
LAppParam const LAppParamEyeBallY = LAppParamMake(ParamEyeBallY);
LAppParam const LAppParamBaseX = LAppParamMake(ParamBaseX);
LAppParam const LAppParamBaseY = LAppParamMake(ParamBaseY);
LAppParam const LAppParamBodyAngleX = LAppParamMake(ParamBodyAngleX);
LAppParam const LAppParamBodyAngleY = LAppParamMake(ParamBodyAngleY);
LAppParam const LAppParamBodyAngleZ = LAppParamMake(ParamBodyAngleZ);

LAppParam const LAppParamEyeBrowLOpen = LAppParamMake(ParamBrowLY);
LAppParam const LAppParamEyeBrowROpen = LAppParamMake(ParamBrowRY);
LAppParam const LAppParamEyeBrowLAngle = LAppParamMake(ParamBrowLAngle);
LAppParam const LAppParamEyeBrowRAngle = LAppParamMake(ParamBrowRAngle);


namespace app {
class Model : public Csm::CubismUserModel {
public:
    Csm::CubismPose *GetPose() {
        return _pose;
    }
    Csm::CubismMotionManager *GetExpressionManager() {
        return _expressionManager;
    }
    Csm::CubismPhysics *GetPhysics() {
        return _physics;
    }
};
}

@interface LAppModel ()
@property (nonatomic, copy) NSString *assetName;
@property (nonatomic, assign) Csm::ICubismModelSetting *modelSetting;
@property (nonatomic, assign) app::Model *model;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *expressionMotionMap;

@property (nonatomic, assign) Csm::CubismPose *modelPose;
@property (nonatomic, assign) Csm::CubismBreath *modelBreath;
@end
@implementation LAppModel
- (void)dealloc {
    [self releaseTexture];
    
    if (_modelSetting != nullptr) {
        delete _modelSetting;
    }
    
    if (_modelBreath) {
        Csm::CubismBreath::Delete(_modelBreath);
        _modelBreath = nullptr;
    }
    
    if (_expressionMotionMap) {
        [[_expressionMotionMap allValues] enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Csm::ACubismMotion *motion = (Csm::ACubismMotion *)[obj pointerValue];
            if (motion) {
                Csm::ACubismMotion::Delete(motion);
            }
        }];
    }
    
    if (_model) {
        delete _model;
    }
}

- (instancetype)initWithName:(NSString *)name
                   glContext:(nonnull LAppOpenGLContext *)glContext {
    self = [super init];
    if (self) {
        _glContext = glContext;
        _assetName = name;
        _modelSetting = nullptr;
        _expressionMotionMap = [[NSMutableDictionary alloc] init];
                
        NSString *model3FilePath = [[NSBundle modelResourceBundleWithName:name] model3FilePath];
        if (model3FilePath == nil) {
            return nil;
        }
        NSData *jsonFile = [[NSData alloc] initWithContentsOfFile:model3FilePath];
        _modelSetting = new Csm::CubismModelSettingJson((const Csm::csmByte *)jsonFile.bytes, (Csm::csmSizeInt)jsonFile.length);
        _model = new app::Model;
    }
    return self;
}

- (void)setMVPMatrixWithSize:(CGSize)size {
    Csm::CubismMatrix44 projectionMatrix;
    CGFloat radio = size.width / size.height;
    CGFloat userScale = 1.8;
    /// 基础坐标缩放
    if (radio > 0) {
        projectionMatrix.Scale(1 / radio * userScale, 1 * userScale);
    } else {
        projectionMatrix.Scale(1 * userScale, 1 / radio * userScale);
    }

    /// 后期可作为可配置项处理
    projectionMatrix.TranslateY(-0.3);
    projectionMatrix.MultiplyByMatrix(self.model->GetModelMatrix());
    self.model->GetRenderer<Csm::Rendering::CubismRenderer_OpenGLES2>()->SetMvpMatrix(&projectionMatrix);
}

- (void)loadAsset {
    [self loadModel];
    [self loadPose];
    //[self loadExpression];
    [self loadPhysics];
    [self createRender];
    [self loadTexture];
}

- (void)loadModel {
    NSString *modelFileName = [NSString stringWithCString:self.modelSetting->GetModelFileName() encoding:NSUTF8StringEncoding];
    if (modelFileName &&
        modelFileName.length > 0) {
        NSString *filePath = [[[NSBundle modelResourceBundleWithName:self.assetName] bundlePath] stringByAppendingPathComponent:modelFileName];
        NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
        self.model->LoadModel((const Csm::csmByte *)fileData.bytes, (Csm::csmSizeInt)fileData.length);
    }
    
    Csm::csmMap<Csm::csmString, Csm::csmFloat32> layout;
    self.modelSetting->GetLayoutMap(layout);

    // モデルのレイアウトを設定。
    self.model->GetModelMatrix()->SetupFromLayout(layout);
}

- (void)loadPose {
    NSString *poseFileName = [NSString stringWithCString:self.modelSetting->GetPoseFileName() encoding:NSUTF8StringEncoding];
    if (poseFileName &&
        poseFileName.length > 0) {
        NSString *filePath = [[[NSBundle modelResourceBundleWithName:self.assetName] bundlePath] stringByAppendingPathComponent:poseFileName];
        NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
        self.model->LoadPose((const Csm::csmByte *)fileData.bytes, (Csm::csmSizeInt)fileData.length);
        self.modelPose = self.model->GetPose();
    }
}

- (void)loadExpression {
    Csm::csmInt32 expressionCount = self.modelSetting->GetExpressionCount();
    for (Csm::csmInt32 i = 0; i < expressionCount; ++i) {
        Csm::csmString expressionNameString = Csm::csmString(self.modelSetting->GetExpressionName(i));
        NSString *expressionName = [NSString stringWithCString:expressionNameString.GetRawString() encoding:NSUTF8StringEncoding] ;
        NSValue *v = [self.expressionMotionMap objectForKey:expressionName];
        if (v != nil) {
            Csm::ACubismMotion *expression = (Csm::ACubismMotion *)v.pointerValue;
            if (expression) {
                Csm::ACubismMotion::Delete(expression);
            }
            [self.expressionMotionMap removeObjectForKey:expressionName];
        }
        
        NSString *expressionFileName = [NSString stringWithCString:self.modelSetting->GetExpressionFileName(i) encoding:NSUTF8StringEncoding];
        NSString *expressionFilePath = [[[NSBundle modelResourceBundleWithName:self.assetName] bundlePath] stringByAppendingPathComponent:expressionFileName];
        
        NSData *fileData = [[NSData alloc] initWithContentsOfFile:expressionFilePath];
        Csm::ACubismMotion *expression = self.model->LoadExpression((const Csm::csmByte *)fileData.bytes, (Csm::csmSizeInt)fileData.length, [expressionName cStringUsingEncoding:NSUTF8StringEncoding]);
        if (expression) {
            [self.expressionMotionMap setObject:[NSValue valueWithPointer:expression] forKey:expressionName];
        }
    }
}

- (void)loadPhysics {
    NSString *fileName = [NSString stringWithCString:self.modelSetting->GetPhysicsFileName() encoding:NSUTF8StringEncoding];
    NSString *filePath = [[[NSBundle modelResourceBundleWithName:self.assetName] bundlePath] stringByAppendingPathComponent:fileName];
    NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
    if (fileData) {
        self.model->LoadPhysics((const Csm::csmByte *)fileData.bytes, (Csm::csmSizeInt)fileData.length);
    }
}

- (void)loadMotion {
    Csm::csmInt32 motionGroupCount = self.modelSetting->GetMotionGroupCount();
    for (Csm::csmInt32 i = 0; i < motionGroupCount; ++i) {
        const Csm::csmChar *motionGroupName = self.modelSetting->GetMotionGroupName(i);
        Csm::csmInt32 motionCount = self.modelSetting->GetMotionCount(motionGroupName);
        for (Csm::csmInt32 j = 0; j < motionCount; ++j) {
            NSString *fileName = [NSString stringWithCString:self.modelSetting->GetMotionFileName(motionGroupName, j) encoding:NSUTF8StringEncoding];
            NSString *filePath = [[[NSBundle modelResourceBundleWithName:self.assetName] bundlePath] stringByAppendingPathComponent:fileName];
            NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
            self.model->LoadMotion((const Csm::csmByte *)fileData.bytes, (Csm::csmSizeInt)fileData.length, motionGroupName);
        }
    }
}

- (void)createRender {
    self.model->CreateRenderer();
}

- (void)loadTexture {
    Csm::csmInt32 textureCount = self.modelSetting->GetTextureCount();
    NSString *textureDirPath = [[NSBundle modelResourceBundleWithName:self.assetName] bundlePath];
    for (int i = 0; i < textureCount; ++i) {
        NSString *textureFileName = [[NSString alloc] initWithCString:self.modelSetting->GetTextureFileName(i) encoding:NSUTF8StringEncoding];
        NSString *textureFilePath = [textureDirPath stringByAppendingPathComponent:textureFileName];
        GLuint texture;
        if ([self.glContext createTexture:&texture withFilePath:textureFilePath]) {
            self.model->GetRenderer<Csm::Rendering::CubismRenderer_OpenGLES2>()->BindTexture(i, texture);
        }
    }
}

- (void)releaseTexture {
    Csm::csmInt32 textureCount = self.modelSetting->GetTextureCount();
    auto map = self.model->GetRenderer<Csm::Rendering::CubismRenderer_OpenGLES2>()->GetBindedTextures();
    for (Csm::csmInt32 i = 0; i < textureCount; ++i) {
        GLuint texture = map[i];
        [self.glContext releaseTexture:texture];
    }
}

- (void)startMotionWithName:(NSString *)motionName
                 fadeInTime:(NSTimeInterval)fadeInTime
                fadeOutTime:(NSTimeInterval)fadeOutTime
                     isLoop:(BOOL)isLoop {
    
}

- (void)startBreath {
    self.modelBreath = Csm::CubismBreath::Create();
    Csm::csmVector<Csm::CubismBreath::BreathParameterData> breathParameters;

    breathParameters.PushBack(Csm::CubismBreath::BreathParameterData(LAppModelParameterID(ParamAngleX), 0.0f, 15.0f, 6.5345f, 0.5f));
    breathParameters.PushBack(Csm::CubismBreath::BreathParameterData(LAppModelParameterID(ParamAngleY), 0.0f, 8.0f, 3.5345f, 0.5f));
    breathParameters.PushBack(Csm::CubismBreath::BreathParameterData(LAppModelParameterID(ParamAngleZ), 0.0f, 10.0f, 5.5345f, 0.5f));
    breathParameters.PushBack(Csm::CubismBreath::BreathParameterData(LAppModelParameterID(ParamBodyAngleX), 0.0f, 4.0f, 15.5345f, 0.5f));
    breathParameters.PushBack(Csm::CubismBreath::BreathParameterData(LAppModelParameterID(ParamBreath), 0.5f, 0.5f, 3.2345f, 0.5f));

    self.modelBreath->SetParameters(breathParameters);
}

- (void)stopBreath {
    Csm::CubismBreath::Delete(self.modelBreath);
    self.modelBreath = nullptr;
}

- (void)startExpressionWithName:(NSString *)expressionName {
    [self startExpressionWithName:expressionName autoDelete:NO priority:kLAppModelDefaultExpressionPriority];
}

- (void)startExpressionWithName:(NSString *)expressionName autoDelete:(BOOL)autoDelete priority:(NSInteger)priority {
    Csm::ACubismMotion *motion = (Csm::ACubismMotion *)[self.expressionMotionMap[expressionName] pointerValue];
    if (motion != nullptr) {
        self.model->GetExpressionManager()->StartMotionPriority(motion, autoDelete, (Csm::csmInt32)priority);
    }
}

- (CGFloat)canvasWidth {
    return self.model->GetModel()->GetCanvasWidth();
}

- (CGFloat)canvasHeight {
    return self.model->GetModel()->GetCanvasHeight();
}

- (NSArray<NSString *> *)expressionName {
    return [self.expressionMotionMap allKeys];
}

#pragma mark - Param
- (NSNumber *)paramMaxValue:(LAppParam)param {
    const Csm::csmInt32 index = self.model->GetModel()->GetParameterIndex(Csm::CubismFramework::GetIdManager()->GetId([param cStringUsingEncoding:NSUTF8StringEncoding]));
    return @(self.model->GetModel()->GetParameterMaximumValue(index));
}

- (NSNumber *)paramMinValue:(LAppParam)param {
    const Csm::csmInt32 index = self.model->GetModel()->GetParameterIndex(Csm::CubismFramework::GetIdManager()->GetId([param cStringUsingEncoding:NSUTF8StringEncoding]));
    return @(self.model->GetModel()->GetParameterMinimumValue(index));
}

- (NSNumber *)paramDefaultValue:(LAppParam)param {
    const Csm::csmInt32 index = self.model->GetModel()->GetParameterIndex(Csm::CubismFramework::GetIdManager()->GetId([param cStringUsingEncoding:NSUTF8StringEncoding]));
    return @(self.model->GetModel()->GetParameterDefaultValue(index));
}

- (void)setParam:(LAppParam)param forValue:(NSNumber *)value {
    [self setParam:param forValue:value width:1.0];
}

- (void)setParam:(LAppParam)param forValue:(NSNumber *)value width:(CGFloat)width {
    self.model->GetModel()->SetParameterValue(Csm::CubismFramework::GetIdManager()->GetId([param cStringUsingEncoding:NSUTF8StringEncoding]),
                                              value.floatValue, width);
    self.model->GetModel()->SaveParameters();
}

- (NSNumber *)paramValue:(LAppParam)param {
    Csm::csmFloat32 value =  self.model->GetModel()->GetParameterValue(Csm::CubismFramework::GetIdManager()->GetId([param cStringUsingEncoding:NSUTF8StringEncoding]));
    return @(value);
}

#pragma mark - On Update
- (void)onUpdateWithParameterUpdate:(dispatch_block_t)block {
    NSTimeInterval deltaTime = self.glContext.deltaTime;
    /// 设置模型参数
    self.model->GetModel()->LoadParameters();
    if (block) {
        block();
    }
    self.model->GetModel()->SaveParameters();
    
    /// 更新并绘制
    if (self.model->GetExpressionManager()) {
        self.model->GetExpressionManager()->UpdateMotion(self.model->GetModel(), deltaTime);
    }
    if (self.model->GetPhysics()) {
        self.model->GetPhysics()->Evaluate(self.model->GetModel(), deltaTime);
    }
    if (self.modelBreath) {
        self.modelBreath->UpdateParameters(self.model->GetModel(), deltaTime);
    }
    if (self.modelPose) {
        self.modelPose->UpdateParameters(self.model->GetModel(), deltaTime);
    }
    self.model->GetModel()->Update();
    self.model->GetRenderer<Csm::Rendering::CubismRenderer_OpenGLES2>()->DrawModel();
}
@end

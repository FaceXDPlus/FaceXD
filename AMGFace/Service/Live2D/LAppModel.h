#import <Foundation/Foundation.h>
#import "LAppOpenGLContext.h"
NS_ASSUME_NONNULL_BEGIN

#define kLAppModelDefaultExpressionPriority (3)

typedef NSString * LAppParam;

extern LAppParam const LAppParamAngleX;
extern LAppParam const LAppParamAngleY;
extern LAppParam const LAppParamAngleZ;
extern LAppParam const LAppParamMouthOpenY;
extern LAppParam const LAppParamMouthForm;
extern LAppParam const LAppParamMouthU;
extern LAppParam const LAppParamEyeLOpen;
extern LAppParam const LAppParamEyeROpen;
extern LAppParam const LAppParamEyeLSmile;
extern LAppParam const LAppParamEyeRSmile;
extern LAppParam const LAppParamEyeBallX;
extern LAppParam const LAppParamEyeBallY;
extern LAppParam const LAppParamBaseX;
extern LAppParam const LAppParamBaseY;
extern LAppParam const LAppParamBodyAngleX;
extern LAppParam const LAppParamBodyAngleY;
extern LAppParam const LAppParamBodyAngleZ;

extern LAppParam const LAppParamEyeBrowLY;
extern LAppParam const LAppParamEyeBrowRY;
extern LAppParam const LAppParamEyeBrowLForm;
extern LAppParam const LAppParamEyeBrowRForm;
extern LAppParam const LAppParamEyeBrowLAngle;
extern LAppParam const LAppParamEyeBrowRAngle;


@interface LAppModel : NSObject
@property (nonatomic, readonly) CGFloat canvasWidth;
@property (nonatomic, readonly) CGFloat canvasHeight;

@property (nonatomic, readonly) NSArray<NSString *> *expressionName;

@property (nonatomic, strong) LAppOpenGLContext *glContext;

- (nullable instancetype)initWithName:(NSString *)name
                            glContext:(LAppOpenGLContext *)glContext;

- (void)setMVPMatrixWithSize:(CGSize)size;

- (void)loadAsset;

- (void)startBreath;
- (void)stopBreath;

- (void)startExpressionWithName:(NSString *)expressionName;
- (void)startExpressionWithName:(NSString *)expressionName
                     autoDelete:(BOOL)autoDelete
                       priority:(NSInteger)priority;

- (NSNumber *)paramMaxValue:(LAppParam)param;
- (NSNumber *)paramMinValue:(LAppParam)param;
- (NSNumber *)paramDefaultValue:(LAppParam)param;
- (NSNumber *)paramValue:(LAppParam)param;
- (void)setParam:(LAppParam)param forValue:(NSNumber *)value;
- (void)setParam:(LAppParam)param forValue:(NSNumber *)value width:(CGFloat)width;

- (void)onUpdateWithParameterUpdate:(dispatch_block_t)block;
@end

NS_ASSUME_NONNULL_END

//
//  XDModelParameterConfiguration.m
//  AMGFace
//
//  Created by CmST0us on 2020/3/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDModelParameterConfiguration.h"

@interface XDModelParameterConfiguration ()
@property (nonatomic, strong) XDModelParameter *parameter;
@end

@implementation XDModelParameterConfiguration

- (instancetype)initWithModel:(LAppModel *)model {
    self = [super init];
    if (self) {
        _parameter = [[XDModelParameter alloc] init];
        _model = model;
    }
    return self;
}

- (void)beforeUpdateParameter:(XDModelParameter *)parameter {
    
}

- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor {
    
}

- (void)afterUpdateParameter:(XDModelParameter *)parameter {
    
}

- (void)reset {
    self.parameter = [[XDModelParameter alloc] init];
}

- (void)commit {
    [[self class].parameterKeyMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *v = [self.parameter valueForKey:obj];
        if (v) {
            [self.model setParam:key forValue:v];
        } else {
            [self.model setParam:key forValue:@(0)];
        }
    }];
}

- (XDModelParameter *)sendParameter {
    return self.parameter;
}

+ (NSDictionary<NSString *,NSString *> *)parameterKeyMap {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            LAppParamAngleX: @"headYaw",
            LAppParamAngleY: @"headPitch",
            LAppParamAngleZ: @"headRoll",
            LAppParamMouthOpenY: @"mouthOpenY",
            LAppParamMouthForm: @"mouthForm",
            LAppParamEyeLOpen: @"eyeLOpen",
            LAppParamEyeROpen: @"eyeROpen",
            LAppParamEyeBrowLY: @"eyeBrowYL",
            LAppParamEyeBrowRY: @"eyeBrowYR",
            LAppParamEyeBrowLForm: @"eyeBrowLForm",
            LAppParamEyeBrowRForm: @"eyeBrowRForm",
            LAppParamEyeBrowLAngle: @"eyeBrowAngleL",
            LAppParamEyeBrowRAngle: @"eyeBrowAngleR",
            LAppParamEyeBallX: @"eyeX",
            LAppParamEyeBallY: @"eyeY",
            LAppParamBodyAngleX: @"bodyAngleX",
            LAppParamBodyAngleY: @"bodyAngleY",
            LAppParamBodyAngleZ: @"bodyAngleZ",
        };
    });
    return map;
}

@end

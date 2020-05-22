//
//  XDModelParameterConfiguration.h
//  AMGFace
//
//  Created by CmST0us on 2020/3/16.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDFaceAnchor.h"
#import "XDModelParameter.h"
#import "LAppModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDModelParameterConfiguration : NSObject
@property (nonatomic, readonly) XDModelParameter *parameter;
@property (nonatomic, weak) LAppModel *model;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithModel:(LAppModel *)model;

- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor;

- (void)reset;
- (void)commit;

/// 所有头部角度，身体角度的取值为[-180, 180] ,单位度
/// 所有表情信息取值[0, 1]
- (XDModelParameter *)sendParameter;

+ (NSDictionary<NSString *, NSString *> *)parameterKeyMap;
@end

NS_ASSUME_NONNULL_END

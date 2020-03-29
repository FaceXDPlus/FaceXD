//
//  XDFilePath.h
//  FaceXD
//
//  Created by CmST0us on 2020/3/29.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XDFilePath : NSObject

+ (NSString *)documentPath;
+ (NSString *)facePredictorModelPath;
+ (BOOL)isFacePredictorModelExist;

@end

NS_ASSUME_NONNULL_END

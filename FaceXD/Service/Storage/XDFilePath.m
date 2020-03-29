//
//  XDFilePath.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/29.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDFilePath.h"

@implementation XDFilePath

+ (NSString *)documentPath {
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    return documentPath;
}

+ (NSString *)facePredictorModelPath {
    NSString *documentPath = [[self class] documentPath];
    NSString *mlPath = [documentPath stringByAppendingPathComponent:@"ml"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:mlPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:mlPath withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    NSString *modelPath = [mlPath stringByAppendingPathComponent:@"face_predictor_model.dat"];
    return modelPath;
}

+ (BOOL)isFacePredictorModelExist {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[self class] facePredictorModelPath]];
}

@end

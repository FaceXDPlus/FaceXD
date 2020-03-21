//
//  EKPixelBuffer.h
//  EKMetalKit
//
//  Created by CmST0us on 2019/11/24.
//  Copyright © 2019 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
NS_ASSUME_NONNULL_BEGIN

@interface EKPixelBuffer : NSObject

@property (nonatomic, readonly) CVPixelBufferRef pixelBuffer;
@property (nonatomic, readonly) NSInteger width;
@property (nonatomic, readonly) NSInteger height;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)aPixelBuffer;
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)aPixelBuffer freeWhenDone:(BOOL)freeWhenDone NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

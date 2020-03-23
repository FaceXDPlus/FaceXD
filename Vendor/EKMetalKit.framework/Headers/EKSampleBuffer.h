//
//  EKSampleBuffer.h
//  EKMetalKit
//
//  Created by CmST0us on 2019/11/24.
//  Copyright © 2019 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN
@interface EKSampleBuffer : NSObject
@property (nonatomic, readonly) CMSampleBufferRef sampleBuffer;
@property (nonatomic, readonly) NSInteger width;
@property (nonatomic, readonly) NSInteger height;
@property (nonatomic, readonly) CMBlockBufferRef dataBuffer;
@property (nonatomic, readonly) CVPixelBufferRef imageBuffer;
@property (nonatomic, readonly) CMItemCount numberOfSamples;
@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) CMFormatDescriptionRef formatDescription;
@property (nonatomic, readonly) CMTime decodeTimeStamp;
@property (nonatomic, readonly) CMTime presentationTimeStamp;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)aSampleBuffer;
- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)aSampleBuffer freeWhenDone:(BOOL)shouldFreeWhenDone NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

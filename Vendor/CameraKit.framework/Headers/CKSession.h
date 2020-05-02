//
//  CKSession.h
//  CameraKit
//
//  Created by CmST0us on 2020/2/3.
//  Copyright © 2020 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKSessionConfiguration.h"
#import "CKCapbility.h"

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const CKSessionErrorDomain;
typedef NS_ENUM(NSUInteger, CKSessionErrorCode) {
    CKSessionErrorCodeUnknow = 1000,
    CKSessionErrorCodeStop = 1001,
};

@class CKSession;

typedef void(^CKSessionConfigBlock)(CKSession *session, CKSessionConfiguration *config);
typedef void(^CKSessionConfigCompletionBlock)(NSError * _Nullable error);

@interface CKSession : NSObject

@property (nonatomic, assign) BOOL manualAudioSession;
@property (nonatomic, readonly) AVCaptureSession *captureSession;
@property (nonatomic, readonly) CKCapbility *capbility;
@property (nonatomic, readonly) BOOL supportMultiCamera;
@property (nonatomic, readonly) CKSessionConfiguration *configuration;

- (NSArray<CKCaptureDevice *> *)currentVideoDevice;
- (NSArray<CKCaptureDevice *> *)currentAudioDevice;

- (nullable instancetype)initWithMultiCameraSupport:(BOOL)supportMultiCamera NS_DESIGNATED_INITIALIZER;

- (void)startSessionWithConfigBlock:(CKSessionConfigBlock)configBlock
                         completion:(CKSessionConfigCompletionBlock)completionBlock;

- (void)stopSessionWithCompletion:(CKSessionConfigCompletionBlock)completionBlock;

- (void)configSession:(CKSessionConfigBlock)configBlock
       withCompletion:(CKSessionConfigCompletionBlock)completionBlock;

- (NSError *)configAudioSessionWithPortType:(AVAudioSessionPort)portType
                                   location:(AVAudioSessionLocation)location
                               polarPattern:(AVAudioSessionLocation)polarPattern;
@end

NS_ASSUME_NONNULL_END

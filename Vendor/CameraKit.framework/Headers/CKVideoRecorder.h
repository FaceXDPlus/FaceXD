//
//  CKVideoRecorder.h
//  CameraKit
//
//  Created by CmST0us on 2020/2/1.
//  Copyright © 2020 eki. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const CKVideoRecorderErrorDomain;

typedef NS_ENUM(NSUInteger, CKVideoRecorderErrorCode) {
    CKVideoRecorderErrorCodeUnknow = 100,
    CKVideoRecorderErrorCodeCreateFileFailed,
};

typedef NS_ENUM(NSUInteger, CKVideoRecorderStatus) {
    CKVideoRecorderInit,
    CKVideoRecorderRunningWaitForFirstFrame,
    CKVideoRecorderRunning,
    CKVideoRecorderStoping,
    CKVideoRecorderStoped,
};

typedef void(^CKVideoRecorderFinishRecordBlock)(NSURL * _Nullable fileURL, NSError * _Nullable error);
typedef void(^CKVideoRecorderStartRecoderCompleteBlock)(NSError * _Nullable error);
typedef void(^CKVideoRecorderStopRecoderCompleteBlock)(NSError * _Nullable error);

@interface CKVideoRecorder : NSObject

@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, assign) BOOL hasAudioTrack;

- (instancetype)initWithURL:(NSURL *)url fileType:(AVFileType)fileType error:(NSError * _Nullable * _Nullable)error;
- (instancetype)initWithURL:(NSURL *)url error:(NSError * _Nullable * _Nullable)error;

- (BOOL)prepareVideoTrackWithSetting:(NSDictionary *)videoTrackSetting;
- (BOOL)prepareAudioTrackWithSetting:(NSDictionary *)AudioTrackSetting;

- (void)registerFinishRecordHandler:(CKVideoRecorderFinishRecordBlock)block;

- (void)startRecordWithCompletion:(CKVideoRecorderStartRecoderCompleteBlock)block;
- (void)stopRecordWithCompletion:(CKVideoRecorderStopRecoderCompleteBlock)block;

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END

//
//  CKCaptureDevice.h
//  CameraKit
//
//  Created by CmST0us on 2020/1/29.
//  Copyright © 2020 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 CKCaptureDeviceID
 MSB
  | <-------CKCaptureDevicePosition-----> |
  | 0 0 0 0 | 0 0 0 0 | 0 0 0 0 | 0 0 0 0 |
  | <---------CKCaptureDeviceType-------> |
  | 0 0 0 0 | 0 0 0 0 | 0 0 0 0 | 0 0 0 0 |
 LSB
 */

typedef NS_OPTIONS(NSUInteger, CKCaptureDeviceTypeID) {
    CKCaptureDeviceTypeMask = 1,
    CKCaptureDevicePositionDeviceTypeMask = 0x10000,
};

typedef NS_OPTIONS(NSUInteger, CKCaptureDeviceType) {
    CKCaptureDeviceTypeBuiltInMicrophone = CKCaptureDeviceTypeMask << 0,
    CKCaptureDeviceTypeBuiltInWideAngleCamera = CKCaptureDeviceTypeMask << 1,
    CKCaptureDeviceTypeBuiltInTelephotoCamera = CKCaptureDeviceTypeMask << 2,
    CKCaptureDeviceTypeBuiltInUltraWideCamera = CKCaptureDeviceTypeMask << 3,
    CKCaptureDeviceTypeBuiltInDualCamera = CKCaptureDeviceTypeMask << 4,
    CKCaptureDeviceTypeBuiltInDualWideCamera = CKCaptureDeviceTypeMask << 5,
    CKCaptureDeviceTypeBuiltInTripleCamera = CKCaptureDeviceTypeMask << 6,
    CKCaptureDeviceTypeBuiltInTrueDepthCamera = CKCaptureDeviceTypeMask << 7,
};

typedef NS_OPTIONS(NSUInteger, CKCaptureDevicePosition) {
    CKCaptureDevicePositionUnspecified = CKCaptureDevicePositionDeviceTypeMask << 0,
    CKCaptureDevicePositionBack = CKCaptureDevicePositionDeviceTypeMask << 1,
    CKCaptureDevicePositionFront = CKCaptureDevicePositionDeviceTypeMask << 2,
};

@interface CKCaptureDevice : NSObject
@property (nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (nonatomic, readonly) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, readonly) NSArray<AVCaptureInputPort *> *inputPorts;

@property (nonatomic, readonly) AVMediaType mediaType;
@property (nonatomic, readonly) AVCaptureDevicePosition position;

@property (nonatomic, readonly) CKCaptureDeviceTypeID deviceTypeID;

@property (nonatomic, readonly) NSError *error;

- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)device
                         deviceTypeID:(CKCaptureDeviceTypeID)deviceTypeID;

- (instancetype)initWithCaptureDeviceID:(NSString *)deviceID
                           deviceTypeID:(CKCaptureDeviceTypeID)deviceTypeID;

- (void)resetInput;

@end

NS_ASSUME_NONNULL_END

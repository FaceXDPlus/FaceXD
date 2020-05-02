//
//  CKCapbility.h
//  CameraKit
//
//  Created by CmST0us on 2020/1/29.
//  Copyright © 2020 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKCaptureDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface CKCapbility : NSObject
@property (nonatomic, readonly) CKCaptureDeviceTypeID supportCaptureDeviceTypeID;
@property (nonatomic, readonly) NSDictionary<NSNumber *, CKCaptureDevice *> *supportCaptureDevice;

@end

NS_ASSUME_NONNULL_END

//
//  CKSessionConfiguration.h
//  CameraKit
//
//  Created by CmST0us on 2020/2/3.
//  Copyright © 2020 eki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CKSessionConfigurationVideoPresent) {
    CKSessionConfigurationVideoPresentManual,
    CKSessionConfigurationVideoPresent1280x720x24,
    CKSessionConfigurationVideoPresent1280x720x30,
    CKSessionConfigurationVideoPresent1280x720x60,
    
    CKSessionConfigurationVideoPresent1920x1080x24,
    CKSessionConfigurationVideoPresent1920x1080x30,
    CKSessionConfigurationVideoPresent1920x1080x60,
    
    CKSessionConfigurationVideoPresent4032x3024x24,
    CKSessionConfigurationVideoPresent4032x3024x30,
    CKSessionConfigurationVideoPresent4032x3024x60,
};

@interface CKSessionConfiguration : NSObject<NSCopying>

@property (nonatomic, copy) NSArray<NSNumber *> *videoDevice;
@property (nonatomic, copy) NSArray<NSNumber *> *audioDevice;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<AVCaptureOutput *> *> *captureOutput;
@property (nonatomic, assign) AVCaptureSessionPreset sessionPresent;

- (void)replaceWithConfiguration:(CKSessionConfiguration *)configuration;
+ (CKSessionConfiguration *)defaultConfiguration;

- (void)addOutput:(AVCaptureOutput *)output forDevice:(NSNumber *)deviceTypeID;
- (void)removeOutput:(AVCaptureOutput *)output;

@end

NS_ASSUME_NONNULL_END

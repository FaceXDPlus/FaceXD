//
//  XDRawJSONSocketService.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDBaseService.h"
NS_ASSUME_NONNULL_BEGIN

@interface XDRawJSONSocketService : XDBaseService

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) NSError *lastError;

- (void)setupServiceWithEndpointHost:(NSString *)endpointHost
                                port:(NSString *)endpointPort
                             timeout:(NSTimeInterval)timeout
                               error:(NSError *__autoreleasing  _Nullable * _Nullable)error;
- (void)disconnect;
@end

NS_ASSUME_NONNULL_END

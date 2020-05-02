//
//  XDWebSocketService.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/25.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDBaseService.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDWebSocketService : XDBaseService
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) NSError *lastError;

- (void)setupServiceWithURL:(NSURL *)url
                    timeout:(NSTimeInterval)timeout
                      error:(NSError **)error;
- (void)disconnect;
@end

NS_ASSUME_NONNULL_END

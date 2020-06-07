//
//  XDWebSocketServerService.h
//  AMGFace
//
//  Created by CmST0us on 2020/6/6.
//  Copyright © 2020 AMG. All rights reserved.
//

#import "XDBaseService.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDWebSocketServerService : XDBaseService

@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic, readonly) NSError *lastError;

- (void)setupServiceWithLocalPort:(NSInteger)port
                            error:(NSError **)error;
- (void)close;

@end

NS_ASSUME_NONNULL_END

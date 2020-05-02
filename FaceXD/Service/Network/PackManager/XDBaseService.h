//
//  XDBaseService.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDBaseNetworkPack.h"
NS_ASSUME_NONNULL_BEGIN

@class XDBaseService;
@protocol XDBaseServiceDelegate <NSObject>
- (void)service:(XDBaseService *)service didReceivePack:(XDBaseNetworkPack *)pack error:(NSError * _Nullable)error;
@end

@interface XDBaseService : NSObject
@property (nonatomic, weak)  id<XDBaseServiceDelegate> delegate;
- (BOOL)canHandlePack:(XDBaseNetworkPack *)pack;
- (void)handlePack:(XDBaseNetworkPack *)pack;
@end

NS_ASSUME_NONNULL_END

//
//  XDBaseNetworkPack.h
//  AMGFace
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XDBaseNetworkPack : NSObject
@property (nonatomic, readonly) NSData *packData;
- (instancetype)initWithData:(NSData *)data;
- (NSData *)serialize;
- (void)deserialize;
@end

NS_ASSUME_NONNULL_END

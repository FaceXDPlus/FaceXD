//
//  XDRawJSONNetworkPack.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDBaseNetworkPack.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDRawJSONNetworkPack : XDBaseNetworkPack
@property (nonatomic, strong) NSDictionary *jsonDictionary;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@end

NS_ASSUME_NONNULL_END

//
//  XDBaseNetworkPack.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDBaseNetworkPack.h"

@implementation XDBaseNetworkPack
- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _packData = data;
    }
    return self;
}
- (NSData *)serialize {
    return [NSData data];
}
- (void)deserialize {
    
}
@end

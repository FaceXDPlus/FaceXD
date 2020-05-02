//
//  XDBaseService.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDBaseService.h"

@implementation XDBaseService
- (BOOL)canHandlePack:(XDBaseNetworkPack *)pack {
    return NO;
}
- (void)handlePack:(XDBaseNetworkPack *)pack {
    
}
@end

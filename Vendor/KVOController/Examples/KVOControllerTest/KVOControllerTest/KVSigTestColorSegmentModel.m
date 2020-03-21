//
//  KVSigTestColorSegmentModel.m
//  KVSigTestApp
//
//  Created by CmST0us on 2018/8/24.
//  Copyright © 2018年 eric3u. All rights reserved.
//

#import "KVSigTestColorSegmentModel.h"

@implementation KVSigTestColorSegmentModel
- (UIColor *)colorOfCurrentIndex {
    switch (self.currentColorIndex) {
        case 0:
            return [UIColor redColor];
            break;
        case 1:
            return [UIColor yellowColor];
            break;
        case 2:
            return [UIColor blueColor];
            break;
        case 3:
            return [UIColor orangeColor];
            break;
        default:
            break;
    }
    return [UIColor blackColor];
}
@end

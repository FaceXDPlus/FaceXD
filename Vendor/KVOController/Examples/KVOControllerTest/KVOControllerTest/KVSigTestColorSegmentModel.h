//
//  KVSigTestColorSegmentModel.h
//  KVSigTestApp
//
//  Created by CmST0us on 2018/8/24.
//  Copyright © 2018年 eric3u. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface KVSigTestColorSegmentModel : NSObject
@property(nonatomic, assign) NSInteger currentColorIndex;
@property(nonatomic, readonly) UIColor *colorOfCurrentIndex;
@end

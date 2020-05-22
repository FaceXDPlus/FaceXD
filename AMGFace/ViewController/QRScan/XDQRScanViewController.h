//
//  XDQRScanViewController.h
//  AMGFace
//
//  Created by CmST0us on 2020/4/17.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^XDQRScanResultBlock)(NSString *stringValue);

@interface XDQRScanViewController : UIViewController
@property (nonatomic, copy) XDQRScanResultBlock resultBlock;
@end

NS_ASSUME_NONNULL_END

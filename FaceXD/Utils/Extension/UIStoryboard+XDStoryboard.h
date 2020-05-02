//
//  UIStoryboard+XDStoryboard.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStoryboard (XDStoryboard)

+ (UIViewController *)xd_viewControllerWithClass:(Class)className;

@end

NS_ASSUME_NONNULL_END

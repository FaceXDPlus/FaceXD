//
//  UIStoryboard+XDStoryboard.m
//  FaceXD
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "UIStoryboard+XDStoryboard.h"

@implementation UIStoryboard (XDStoryboard)

+ (UIStoryboard *)xd_storyboard {
    return [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
}

+ (UIViewController *)xd_viewControllerWithClass:(Class)className {
    return [[self xd_storyboard] instantiateViewControllerWithIdentifier:NSStringFromClass(className)];
}

@end

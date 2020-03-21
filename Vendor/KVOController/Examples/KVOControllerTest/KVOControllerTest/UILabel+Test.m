//
//  UILabel+Test.m
//  KVSigTestApp
//
//  Created by CmST0us on 2019/8/24.
//  Copyright © 2019 eric3u. All rights reserved.
//

#import "UILabel+Test.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static char *testStringKey = "testStringKey";

@implementation UILabel (Test)

- (NSString *)testString {
    id s = objc_getAssociatedObject(self, testStringKey);
    if (s == nil) {
        NSString *ss = @"";
        objc_setAssociatedObject(self, testStringKey, ss, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return ss;
    }
    return s;
}

- (void)setTestString:(NSString *)testString {
    objc_setAssociatedObject(self, testStringKey, testString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

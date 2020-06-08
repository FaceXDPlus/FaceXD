//
//  UIDevice+UUID.m
//  AMGFace
//
//  Created by CmST0us on 2020/6/8.
//  Copyright © 2020 AMG. All rights reserved.
//

#import "UIDevice+UUID.h"
#import "AMGKeychainHelper.h"

#define kAMGFaceUUIDKey @"com.AMG.AMGFaces.UUID"

@implementation UIDevice (UUID)
+ (NSString *)UUID {
    NSString * strUUID = (NSString *)[AMGKeychainHelper load:kAMGFaceUUIDKey];
    if (strUUID != nil &&
        [strUUID isKindOfClass:[NSString class]] &&
        strUUID.length > 0) {
        return strUUID;
    }
    
    NSString *genUUID = [NSUUID UUID].UUIDString;
    [AMGKeychainHelper save:kAMGFaceUUIDKey data:genUUID];
    return genUUID;
}
@end
